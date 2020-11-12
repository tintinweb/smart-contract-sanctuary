// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./IERC20.sol";

import "./ICryptoPunksMarket.sol";
import "./Pausable.sol";

contract PunkFund is Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    ICryptoPunksMarket private cpm;
    IERC20 private pt;
    mapping(uint256 => address) private whoStaged;
    EnumerableSet.UintSet private cryptoPunksDeposited;
    uint256 private randNonce = 0;

    event CryptoPunkStaged(uint256 punkId, address indexed from);
    event CryptoPunkDeposited(uint256 punkId, address indexed from);
    event CryptoPunkRedeemed(uint256 punkId, address indexed to);

    constructor(address cryptoPunksAddress, address punkTokenAddress) public {
        cpm = ICryptoPunksMarket(cryptoPunksAddress);
        pt = IERC20(punkTokenAddress);
    }

    function getWhoStaged(uint256 cryptoPunkId) public view returns (address) {
        return whoStaged[cryptoPunkId];
    }

    function getCryptoPunkAtIndex(uint256 index) public view returns (uint256) {
        return cryptoPunksDeposited.at(index);
    }

    function getNumCryptoPunksDeposited() public view returns (uint256) {
        return cryptoPunksDeposited.length();
    }

    function genPseudoRand(uint256 modulus) internal returns (uint256) {
        randNonce = randNonce.add(1);
        return
            uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) %
            modulus;
    }

    function isCryptoPunkDeposited(uint256 punkId) public view returns (bool) {
        uint256 numCryptoPunks = cryptoPunksDeposited.length();
        for (uint256 i = 0; i < numCryptoPunks; i++) {
            uint256 cryptoPunkId = cryptoPunksDeposited.at(i);
            if (cryptoPunkId == punkId) {
                return true;
            }
        }
        return false;
    }

    function stageCryptoPunk(uint256 punkId) public whenNotPaused {
        require(cpm.punkIndexToAddress(punkId) == msg.sender);
        whoStaged[punkId] = msg.sender;
        emit CryptoPunkStaged(punkId, msg.sender);
    }

    function withdrawPunkToken(uint256 punkId) public whenNotPaused {
        require(whoStaged[punkId] == msg.sender);
        require(cpm.punkIndexToAddress(punkId) == address(this));
        cryptoPunksDeposited.add(punkId);
        emit CryptoPunkDeposited(punkId, msg.sender);
        pt.transfer(msg.sender, 10**18);
    }

    function redeemCryptoPunk() public whenNotPaused {
        uint256 cpLength = cryptoPunksDeposited.length();
        uint256 randomIndex = genPseudoRand(cpLength);
        uint256 selectedPunk = cryptoPunksDeposited.at(randomIndex);
        require(pt.transferFrom(msg.sender, address(this), 10**18));
        cryptoPunksDeposited.remove(selectedPunk);
        cpm.transferPunk(msg.sender, selectedPunk);
        emit CryptoPunkRedeemed(selectedPunk, msg.sender);
    }

    function migrate(address to) public onlyOwner whenNotLocked {
        uint256 punkBalance = pt.balanceOf(address(this));
        pt.transfer(to, punkBalance);
        uint256 numCryptoPunks = cryptoPunksDeposited.length();
        for (uint256 i = 0; i < numCryptoPunks; i++) {
            uint256 cryptoPunkId = cryptoPunksDeposited.at(i);
            cpm.transferPunk(to, cryptoPunkId);
        }
    }

    function stageRetroactively(uint256 punkId, address prevHolder)
        public
        onlyOwner
    {
        require(cpm.punkIndexToAddress(punkId) == address(this));
        require(!isCryptoPunkDeposited(punkId));
        whoStaged[punkId] = prevHolder;
        emit CryptoPunkStaged(punkId, prevHolder);
    }

    function redeemRetroactively(address newHolder) public onlyOwner {
        uint256 circulatingPunkSupply = pt.totalSupply() -
            pt.balanceOf(address(this));
        uint256 expectedCryptoPunksDeposited = circulatingPunkSupply.div(
            10 ^ 18
        );
        if (cryptoPunksDeposited.length() > expectedCryptoPunksDeposited) {
            uint256 randomIndex = genPseudoRand(cryptoPunksDeposited.length());
            uint256 selectedPunk = cryptoPunksDeposited.at(randomIndex);
            cryptoPunksDeposited.remove(selectedPunk);
            cpm.transferPunk(newHolder, selectedPunk);
            emit CryptoPunkRedeemed(selectedPunk, newHolder);
        }
    }
}
