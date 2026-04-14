# KurobaEx-mpv-libs

A storage for mpv pre-built libraries that can be then downloaded and used by the KurobaEx.
The source code can be found in the main repository.

### How to build
- You will need Docker.
- Run `sudo docker build --no-cache -t mpv-android-build .` in the directory where the `Dockerfile` is located.
- After it's done building you just need to copy the libraries out of the Docker container like this:
```
# Create new temp container
docker create --name mpv-tmp mpv-android-build
# Copy the libs out of it
docker cp mpv-tmp:/build/app/src/main/libs ./libs
# Remove the temp container
docker rm mpv-tmp
```
If you did any breaking changes (like adding/removing a new JNI function to be used in Android code) you need to bump the `player_version` in `app/src/main/jni/main.cpp` and then also make sure it's the same as in `MPVLib.SUPPORTED_MPV_PLAYER_VERSION`.
