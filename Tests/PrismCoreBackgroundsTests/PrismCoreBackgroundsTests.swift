import Testing
@testable import PrismCoreBackgrounds

@Test func standardConstructionKeepsThePrismBackgroundContract() {
    #expect(PrismBackgroundConstruction.washOpacity == 0.30)
    #expect(PrismBackgroundConstruction.middleStopLocation == 0.48)
    #expect(PrismBackgroundConstruction.highlightFadeOpacity == 0.38)
    #expect(PrismBackgroundConstruction.highlightRadiusScale == 0.82)
    #expect(PrismBackgroundConstruction.glowOpacity == 0.82)
    #expect(PrismBackgroundConstruction.glowRadiusScale == 0.64)
}


