// SPDX-License-Identifier: MIT

/**---------------------------------
Website: https://zadauniverse.com
Telegram: https://t.me/zadabsc
Twitter: https://twitter.com/zadabsc
----------------------------------
*/

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ZadaToken.sol";

contract Controller is Ownable {
    using SafeMath for uint256;

    Zada public zContract;

    address[] public signers = [
        0x97B7e24A17494B46905Ddc13FBC8E9011496E498,
        0xab697c933e118794B89E89dD9f9998603eB85D2D,
        0xF860486d668821aDb8FE3c78de20Ca5C90aAe3ab,
        0x33E3761AEADE9540A09A2E2B86D981A26205ece1,
        0xF06BF61831C996CCFFAF081b8A3cF6eFDBd86275,
        0xC3A2d356F61CF603DBC75be7229FcDBfaB83eE0b
    ];

    mapping(uint256 =>mapping(address => bool)) signatures;

    constructor(Zada _address) public {
        zContract = Zada(_address);
    }

    function sign(uint256 _functionID) public {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        signatures[_functionID][msg.sender] = true;
    }

    function setNotValidForLMS(address _address) public signAuthorized(0) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setNotValidForLMS(_address);
        clearSigns(0);
    }

    function setMinimumSwapAmount(uint256 _minSwap) public signAuthorized(1) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setMinimumSwapAmount(_minSwap);
        clearSigns(1);
    }

    function setZT(IERC20 _ZadaToken) public signAuthorized(2) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setZT(_ZadaToken);
        clearSigns(2);
    }

    function updateDividendTracker(address newAddress) public signAuthorized(3) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.updateDividendTracker(newAddress);
        zContract.excludeFromDividends(zContract.deadWallet());
        zContract.excludeFromDividends(zContract.uniswapV2Pair());
        clearSigns(3);
    }

    function updateUniswapV2Router(address newAddress, bool value) public signAuthorized(4) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.updateUniswapV2Router(newAddress);
        zContract.setAutomatedMarketMakerPair(zContract.uniswapV2Pair(), value);
        clearSigns(4);
    }

    function excludeFromFees(address account, bool excluded) public signAuthorized(5) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.excludeFromFees(account, excluded);
        clearSigns(5);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public signAuthorized(6) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.excludeMultipleAccountsFromFees(accounts, excluded);
        clearSigns(6);
    }

    function setLastManStandingWallet(address payable wallet) public signAuthorized(7) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setLastManStandingWallet(wallet);
        clearSigns(7);
    }

    function setMarketingWallet(address payable wallet) public signAuthorized(8) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setMarketingWallet(wallet);
        clearSigns(8);
    }

    function setADARewardsFee(uint256 value) public signAuthorized(9) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        uint256 totalFees = zContract.liquidityFee().add(zContract.marketFee()).add(zContract.lmsFee()).add(value);
        require(totalFees <= 18, "ZADA: FEES EXCEED MAXIMUM OF 18%");
        zContract.setADARewardsFee(value);
        clearSigns(9);
    }

    function setLiquidityFee(uint256 value) public signAuthorized(10) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        uint256 totalFees = zContract.ADARewardsFee().add(zContract.marketFee()).add(zContract.lmsFee()).add(value);
        require(totalFees <= 18, "ZADA: FEES EXCEED MAXIMUM OF 18%");
        zContract.setLiquidityFee(value);
        clearSigns(10);
    }

    function setMarketFee(uint256 value) public signAuthorized(11) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        uint256 totalFees = zContract.ADARewardsFee().add(zContract.liquidityFee()).add(zContract.lmsFee()).add(value);
        require(totalFees <= 18, "ZADA: FEES EXCEED MAXIMUM OF 18%");
        zContract.setMarketFee(value);
        clearSigns(11);
    }

    function setLMSFee(uint256 value) public signAuthorized(12) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        uint256 totalFees = zContract.ADARewardsFee().add(zContract.liquidityFee()).add(zContract.marketFee()).add(value);
        require(totalFees <= 18, "ZADA: FEES EXCEED MAXIMUM OF 18%");
        zContract.setLMSFee(value);
        clearSigns(12);
    }

    function setCoolDownLMS(uint256 _time) public signAuthorized(13) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setCoolDownLMS(_time);
        clearSigns(13);
    }

    function startLastManStanding() public signAuthorized(14) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.startLastManStanding();
        clearSigns(14);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public signAuthorized(15) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.setAutomatedMarketMakerPair(pair, value);
        clearSigns(15);
    }

    function blacklistAddress(address account, bool value) public signAuthorized(16) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.blacklistAddress(account, value);
        clearSigns(16);
    }

    function updateGasForProcessing(uint256 newValue) public signAuthorized(17) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.updateGasForProcessing(newValue);
        clearSigns(17);
    }

    function updateClaimWait(uint256 claimWait) public signAuthorized(18) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.updateClaimWait(claimWait);
        clearSigns(18);
    }

    function excludeFromDividends(address account) public signAuthorized(19) {
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.excludeFromDividends(account);
        clearSigns(19);
    }
    
    function transferOwner(address _newOwner) public signAuthorized(20){
        require(isSigner(msg.sender) == true, "ZADA: NOT AN APPROVED SIGNER");
        zContract.transferOwnership(_newOwner);
    }       

    //MULTISIG FUNCTIONS
    function isSigner(address _address) public view returns(bool) {
        for(uint256 i = 0; i < signers.length; i++) {
            if(_address == signers[i]) {
                return true;
            }
        }
        return false;
    }

    function clearSigns(uint256 _functionID) internal {
        require(isSigner(msg.sender) == true, "ZADA: NOT AUTHORIZED TO CLEAR SIGNATURES");
        for(uint256 i = 0; i < signers.length; i++) {
            signatures[_functionID][signers[i]] = false;
        }
    }

    modifier signAuthorized(uint256 _functionID) {

        uint256 totalApproved = 0;

        for(uint256 i = 0; i < signers.length; i++) {
            if(signatures[_functionID][signers[i]] == true) {
                totalApproved++;
            }
        }

        require(totalApproved >= signers.length.div(2), "ZADA: NOT ENOUGH SIGNERS APPROVED");
        _;
    }
}