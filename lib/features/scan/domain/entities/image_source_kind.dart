/// Where an image comes from.
///
/// The domain layer names the source itself, so it does not import the picker
/// package. The data layer maps this to the package enum.
enum ImageSourceKind { camera, gallery }
