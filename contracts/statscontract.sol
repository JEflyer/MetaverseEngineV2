//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract StatsContract {
    struct Stats {
        uint wins;
        uint losses;
    }

    mapping (address => mapping(uint256 => Stats)) public stats;

    address public signatureVerifier;
    address private deployer;

    constructor(){
        deployer = msg.sender;
    }

    modifier onlyVerfier{
        require(msg.sender == signatureVerifier,"ERR:NV");//NV => Not Verifier
        _;
    }

    function init(address sigVerifier) external {
        require(msg.sender == deployer,"ERR:ND");//ND => Not Deployer
        require(signatureVerifier == address(0),"ERR:AS");//AS => Already Set
        signatureVerifier = sigVerifier;
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
