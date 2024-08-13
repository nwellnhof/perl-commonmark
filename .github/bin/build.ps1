Param (
  $VERSION
)

$BASENAME = "cmark-${VERSION}"
$PREFIX = "$env:GITHUB_WORKSPACE/${BASENAME}"

if (Test-Path "Makefile") {
  make realclean
}

echo "Building ${BASENAME} in ${PREFIX}";
C:\msys64\usr\bin\wget.exe -q "https://github.com/jgm/cmark/archive/${VERSION}.tar.gz"
tar -zxf "${VERSION}.tar.gz"

cd "${BASENAME}"

# Test shared library. The static library requires to define
# CMARK_STATIC_DEFINE on Windows.
$flags = ''
if ($VERSION -ge '0.31.') {
    $flags = '-D BUILD_SHARED_LIBS=ON'
} elseif ($VERSION -ge '0.28.') {
    $flags = '-D CMARK_STATIC=OFF'
}

cmake `
    -G 'MinGW Makefiles' `
    -D CMAKE_BUILD_TYPE=Release `
    -D CMAKE_C_COMPILER=gcc `
    -D CMAKE_CXX_COMPILER=g++ `
    -D CMAKE_INSTALL_PREFIX="${PREFIX}" `
    $flags `
    -S . -B build
cmake --build build --target install --config Release

# libcmark 0.27 and lower always build the static library
# which Perl seems to prefer, so we delete it manually.
if (Test-Path lib/libcmark.a) {
    rm lib/libcmark.a
}

cd ..

echo "Building and testing CommonMark"
$env:PATH += ";${PREFIX}/bin"
perl Makefile.PL INC="-I${PREFIX}/include" LIBS="-L${PREFIX}/lib -lcmark"
make test TEST_VERBOSE=1
