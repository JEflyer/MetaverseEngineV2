//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract StatsContract {
    struct Stats {
        uint wins;
        uint losses;
    }

    mapping (address => mapping(uint256 => Stats)) public stats;

    address public signatureVerifier;

    constructor(address sigVerifier){
        signatureVerifier = sigVerifier;
    }

    modifier onlyVerfier{
        require(msg.sender == signatureVerifier,"ERR:NV");//NV => Not Verifier
        _;
    }

    function incrementWins(uint256 tokenID, address minter) external onlyVerfier {
        stats[minter][tokenID].wins++;
    }

    function incrementLosses(uint256 tokenID, address minter) external onlyVerfier {
        stats[minter][tokenID].losses++;
    }

    function getStats(uint256 tokenID, address minter) external view returns (uint wins, uint losses) {
        return (stats[minter][tokenID].wins, stats[minter][tokenID].losses);
    }
}
