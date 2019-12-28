# This script is called from travis.yml for the "Docs" job
#
# Actual deployment will only happen if the TRAVIS environment variable is set.
# It is possible to run this script locally (outside of Travis) for a test of
# artifact building by setting only the TRAVIS_TAG variable, e.g.:
#
#   TRAVIS_TAG=v1.0.0-rc1 sh .travis/doctr_build.sh
#
# This will leave artifacts in the docs/_build/artifacts folder.

echo "# DOCTR - deploy documentation"

echo "## Generate main html documentation"
tox -e docs

if [ ! -z "$TRAVIS_TAG" ]; then

    echo "Deploying as TAG $TRAVIS_TAG"

    echo "## Generate documentation downloads"
    # We generate documentation downloads only for tags (which are assumed to
    # correspond to releases). Otherwise, we'd quickly fill up git with binary
    # artifacts for every single push.
    mkdir docs/_build/artifacts

    # We build the documentation artifacts in the temporary
    # docs/_build/artifacts. These are then deployed to the cloud, and a
    # _download file is written to the main html documentation containing links
    # to all the artifacts. The find_downloads function in doctr_post_process
    # will then later transfer those links into versions.json

    echo "### [zip]"
    cp -r docs/_build/html docs/_build/pypkg_m7rap-$TRAVIS_TAG
    cd docs/_build || exit
    zip -r "pypkg_m7rap-$TRAVIS_TAG.zip" "pypkg_m7rap-$TRAVIS_TAG"
    rm -rf "pypkg_m7rap-$TRAVIS_TAG"
    cd ../../ || exit
    mv "docs/_build/pypkg_m7rap-$TRAVIS_TAG.zip" docs/_build/artifacts

    echo "### [pdf]"
    tox -e docs -- -b latex _build/latex
    tox -e run-cmd -- python docs/build_pdf.py docs/_build/latex/*.tex
    echo "finished latex compilation"
    mv docs/_build/latex/*.pdf "docs/_build/artifacts/pypkg_m7rap-$TRAVIS_TAG.pdf"

    echo "### [epub]"
    tox -e docs -- -b epub _build/epub
    mv docs/_build/epub/*.epub "docs/_build/artifacts/pypkg_m7rap-$TRAVIS_TAG.epub"

    if [ ! -z "$TRAVIS" ]; then

        # upload to bintray
        # Depends on $BINTRAY_USER, $BINTRAY_REPO, $BINTRAY_PACKAGE, and secret $BINTRAY_TOKEN from .travis.yml
        echo "Upload artifacts to bintray"
        for filename in docs/_build/artifacts/*; do
            BINTRAY_UPLOAD="https://api.bintray.com/content/$BINTRAY_USER/$BINTRAY_REPO/$BINTRAY_PACKAGE/$TRAVIS_TAG/$(basename $filename)"
            echo "Uploading $filename artifact to $BINTRAY_UPLOAD"
            response=$(curl -T "$filename" "-u$BINTRAY_USER:$BINTRAY_TOKEN" "$BINTRAY_UPLOAD")
            if [ -z "${response##*success*}" ]; then
                echo "Uploaded $filename: $response"
                echo "https://dl.bintray.com/$BINTRAY_USER/$BINTRAY_REPO/$(basename $filename)" >> docs/_build/html/_downloads
            else
                echo "Error: Failed to upload $filename: $response" && sync && exit 1
            fi
        done
        echo "Publishing release on bintray"
        BINTRAY_RELEASE="https://api.bintray.com/content/$BINTRAY_USER/$BINTRAY_REPO/$BINTRAY_PACKAGE/$TRAVIS_TAG/publish"
        response=$(curl -X POST "-u$BINTRAY_USER:$BINTRAY_TOKEN" "$BINTRAY_RELEASE")
        if [ -z "${response##*files*}" ]; then
            echo "Finished bintray release : $response"
        else
            echo "Error: Failed publish release on bintray: $response" && sync && exit 1
        fi

        echo "docs/_build/html/_downloads:"
        cat docs/_build/html/_downloads

        rm -rf docs/_build/artifacts

    fi

elif [ ! -z "$TRAVIS_BRANCH" ]; then

    echo "Deploying as BRANCH $TRAVIS_BRANCH"

else

    echo "At least one of TRAVIS_TAG and TRAVIS_BRANCH must be set"
    sync
    exit 1

fi

# Deploy
if [ ! -z "$TRAVIS" ]; then
    echo "## pip install doctr"
    python -m pip install doctr
    echo "## doctr deploy"
    if [ ! -z "$TRAVIS_TAG" ]; then
        DEPLOY_DIR="$TRAVIS_TAG"
    else
        DEPLOY_DIR="$TRAVIS_BRANCH"
    fi
    python -m doctr deploy --key-path docs/doctr_deploy_key.enc \
        --command="git show $TRAVIS_COMMIT:.travis/doctr_post_process.py > post_process.py && git show $TRAVIS_COMMIT:.travis/versions.py > versions.py && python post_process.py" \
        --built-docs docs/_build/html --no-require-master --build-tags "$DEPLOY_DIR"
fi

echo "# DOCTR - DONE"
