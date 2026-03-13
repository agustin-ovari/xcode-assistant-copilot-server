public actor ConfigurationStore {
    private var configuration: ServerConfiguration

    public init(initial: ServerConfiguration) {
        self.configuration = initial
    }

    public func current() -> ServerConfiguration {
        configuration
    }

    public func update(_ new: ServerConfiguration) {
        configuration = new
    }
}
