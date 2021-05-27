// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./ERC20.sol";

/**
 * @title Interface for other's contracts use
 * @dev This functions will be called by other's contracts
 */
interface IERAC {
    /**
     * @dev Query the TokenId(ERAC) list for the specified account.
     *
     */
    function getTokenIds(address owner) external view returns (uint256[] memory);
}

contract ERACBonus is Ownable {

    address private _eracAddress;
    mapping(uint256 => uint256) private _withdrawalAmount;
    mapping(address => mapping(uint256 => uint256)) private _tokenWithdrawalAmount;
    uint256 private balance;
    mapping(address => uint256) private accountEnterBalance;

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private tokens;
    mapping(address => uint256) private balances;

    constructor(address eracAddress) {
        require(eracAddress != address(0), "ERACBonus: address is the zero address");
        _eracAddress = eracAddress;
    }

    modifier validTokenId(uint256 tokenId) {
        require(tokenId >= 1 && tokenId <= 10000, "ERACBonus: operator an invalid ERAC token id");
        _;
    }

    function setNFTAddress(address addr) public onlyOwner {
        require(addr != address(0), "ERACBonus: address is the zero address");
        _eracAddress = addr;
    }

    function addToken(address tokenAddr) public onlyOwner {
        require(tokenAddr != address(0));
        tokens.add(tokenAddr);
    }

    function removeToken(address tokenAddr) public onlyOwner {
        tokens.remove(tokenAddr);
    }

    function recharge(address tokenAddr, uint256 amount) public {
        require(tokenAddr != address(0));
        require(tokens.contains(tokenAddr), "this token is not allow");
        require(amount > 0, "rechage amount must be > 0");
        require(ERC20(tokenAddr).transferFrom(msg.sender, address(this), amount), "recharge failed");
        balances[tokenAddr] = balances[tokenAddr].add(amount);
    }

    fallback() payable external {}

    receive() payable external {
        require(msg.value > 0, "recharge must be >0");
        balance = balance.add(msg.value);
    }

    function _getLevel(uint256 id) private pure validTokenId(id) returns (uint256) {
        return id > 6000 ? 1 : (id > 4000 ? 2 : (id > 3000 ? 3 : (id > 2000 ? 4 : (id > 1000 ? 5 : (id > 300 ? 6 : (id > 100 ? 7 : (id > 10 ? 8 : 9)))))));
    }

    function getTotalFeeETH() public view returns (uint256){
        return balance;
    }

    function getTotalFeeToken(address tokenAddr) public view returns (uint256){
        require(tokenAddr != address(0));
        require(tokens.contains(tokenAddr), "this token is not allow");
        return balances[tokenAddr];
    }

    function balanceOfERAC(uint256 tokenId) public validTokenId(tokenId) view returns (uint256) {
        uint16[10] memory levelBonusNum = [0, 15, 30, 60, 80, 100, 171, 800, 1778, 20000];
        return balance * levelBonusNum[_getLevel(tokenId)] / 1000000 - _withdrawalAmount[tokenId];
    }

    function balanceOfERACToken(address tokenAddr, uint256 tokenId) public validTokenId(tokenId) view returns (uint256) {
        uint16[10] memory levelBonusNum = [0, 15, 30, 60, 80, 100, 171, 800, 1778, 20000];
        return balances[tokenAddr] * levelBonusNum[_getLevel(tokenId)] / 1000000 - _tokenWithdrawalAmount[tokenAddr][tokenId];
    }

    function getBalanceOfAccountETH(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = IERAC(_eracAddress).getTokenIds(owner);
        uint length = tokenIds.length;
        if (length == 0) {
            return 0;
        }
        uint256 totalAmount = 0;
        for (uint i = 0; i < length; ++i) {
            totalAmount = totalAmount.add(balanceOfERAC(tokenIds[i]));
        }

        return totalAmount;
    }

    function getTokenList() public view returns (address [] memory addrs){
        uint length = tokens.length();
        addrs = new address[](length);
        for (uint i = 0; i < length; ++i) {
            addrs[i] = tokens.at(i);
        }
        return addrs;
    }

    function containsToken(address tokenAddr) public view returns (bool){
        return tokens.contains(tokenAddr);
    }

    function getBalanceOfAccountToken(address tokenAddr, address owner) public view returns (uint256) {
        require(tokenAddr != address(0));
        require(tokens.contains(tokenAddr), "this token is not allow");
        uint256[] memory tokenIds = IERAC(_eracAddress).getTokenIds(owner);
        uint length = tokenIds.length;
        if (length == 0) {
            return 0;
        }
        uint256 totalAmount = 0;
        for (uint i = 0; i < length; ++i) {
            totalAmount = totalAmount.add(balanceOfERACToken(tokenAddr, tokenIds[i]));
        }

        return totalAmount;
    }


    function withdrawETH() public returns (bool) {
        uint256[] memory tokenIds = IERAC(_eracAddress).getTokenIds(msg.sender);
        require(tokenIds.length > 0, "ERACBonus:you has no ERAC token");

        uint256 withdrawBalance = 0;
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 balanceOfThis = balanceOfERAC(tokenId);
            if (balanceOfThis > 0) {
                _withdrawalAmount[tokenId] = _withdrawalAmount[tokenId].add(balanceOfThis);
                withdrawBalance = withdrawBalance.add(balanceOfThis);
            }
        }

        require(withdrawBalance > 0, "ERACBonus: since last withdraw has no new Bonus produce");
        payable(msg.sender).transfer(withdrawBalance);

        return true;
    }

    function withdrawToken(address tokenAddr) public returns (bool) {
        require(tokenAddr != address(0));
        require(tokens.contains(tokenAddr), "this token is not allow");
        uint256[] memory tokenIds = IERAC(_eracAddress).getTokenIds(msg.sender);
        require(tokenIds.length > 0, "ERACBonus:you has no ERAC token");

        uint256 withdrawBalance = 0;
        for (uint i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 balanceOfThis = balanceOfERACToken(tokenAddr, tokenId);
            if (balanceOfThis > 0) {
                _tokenWithdrawalAmount[tokenAddr][tokenId] = _tokenWithdrawalAmount[tokenAddr][tokenId].add(balanceOfThis);
                withdrawBalance = withdrawBalance.add(balanceOfThis);
            }
        }

        require(withdrawBalance > 0, "ERACBonus: since last withdraw has no new Bonus produce");
        require(ERC20(tokenAddr).transfer(msg.sender, withdrawBalance), "recharge failed");

        return true;
    }
}