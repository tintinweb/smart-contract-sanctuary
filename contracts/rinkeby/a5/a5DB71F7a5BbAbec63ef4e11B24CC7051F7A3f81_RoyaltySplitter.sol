// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IWolfPack.sol';
import './Ownable.sol';
import './IERC20.sol';

contract RoyaltySplitter is Ownable {

    IWolfPack private WolfPackContract;
    IERC20 private wrappedEth;
    IERC20 private denToken;
    
    address private communityWallet;
    uint256 private _totalReleased;

    mapping(address => uint16) private minterToAmountMinted;
    mapping(address => uint256) private _released;

    event PaymentReceived(address from, uint amount);
    event PaymentReleased(address to, uint256 amount);

    function setWolfPackContractAddress(address contractAddress) external onlyOwner {
        WolfPackContract = IWolfPack(contractAddress);
    }

    function setWrappedEthContractAddress(address contractAddress) external onlyOwner {
        wrappedEth = IERC20(contractAddress);
    }

    function setDenTokenContractAddress(address contractAddress) external onlyOwner {
        denToken = IERC20(contractAddress);
    }
    
    function setCommunityWallet(address _address) external onlyOwner {
        communityWallet = _address;
    }

    function getCommunityWallet() external view returns(address) {
        return communityWallet;
    }


    function withdrawWETH(address _to) external onlyOwner {
        wrappedEth.transfer(_to, wrappedEth.balanceOf(address(this)));
    }

    function withdrawDEN(address _to) external onlyOwner {
        denToken.transfer(_to, denToken.balanceOf(address(this)));
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function pullPayment(address payable account) public {
        require(account == msg.sender, "You can only withdraw to your own wallet!");
        require(
            minterToAmountMinted[account] > 0 ||
            WolfPackContract.balanceOf(account) > 0 ||
            account == communityWallet,
            "Account not eligible for withdrawal!"
        );
        require(avalibleWithdrawalBalance(account) > 0, "Nothing avalible to withdraw!");

        uint payment = avalibleWithdrawalBalance(account);

        _released[account] += payment;
        _totalReleased += payment;

        bool success = account.send(payment);
        require(success, "Payment didn't go through");
        emit PaymentReleased(account, payment);
    }

    function avalibleWithdrawalBalance(address account) public view returns(uint) {

        uint totalReceived = address(this).balance + _totalReleased;
        uint payment;
        uint amountMinted = minterToAmountMinted[account];
        uint balance = _tokenBalance(account);

        if (amountMinted > 0) {
            payment += ((totalReceived * 3) * amountMinted) / 11900;
        }
        if (balance > 0) {
            payment += ((totalReceived * 2) * balance) / 11900;
        }
        if (account == communityWallet) {
            payment += (totalReceived * 2) / 7;
        }
        
        payment -= _released[account];
        return payment;
    }

    function _tokenBalance(address account) public view returns(uint) {
        uint balance = WolfPackContract.balanceOf(account);
        if (account == communityWallet) {
            return (balance + (1701 - WolfPackContract.getSupply()));
        } else {
            return balance;
        }
    }

    /**
     * @dev Returns an array of the minters.
     *      If they were airdropped it will set it to the team address.
     *      To add a minter for a specific ID, call the WolfPack contract. 
     */
    function mintersList() external view returns(address[] memory minters) {
        minters = new address[](1700);
        for (uint256 i = 1; i < 1701; i++) {
            if (WolfPackContract.getTokenMinter(i) != address(0)) {
                minters[i] = WolfPackContract.getTokenMinter(i);
            } else {
                minters[i] = communityWallet;
            }
        }
    }

    /**
     * @dev Gets the amount of tokens a minter has minted.
     */
    function amountPerMinter(address _minter) external view returns(uint16) {
        uint16 counter;
        if (_minter == communityWallet) {
            for (uint256 i = 1; i <= 1700; i++) {
                address tokenMinter = WolfPackContract.getTokenMinter(i);
                if (tokenMinter == address(0) || tokenMinter == _minter) {
                    counter += 1;
                }
            }
        } else {
            for (uint256 i = 1; i <= 1700; i++) {
                if (WolfPackContract.getTokenMinter(i) == _minter) {
                    counter += 1;
                }
            }
        }
        return counter;
    }

    /**
     * @dev get minterToAmountMinted mapping
     * @notice this can be used to verify if the token amount per minter is set correctly.
     */
    function getMinterToAmountMinted(address minter) external view returns(uint16) {
        return minterToAmountMinted[minter];
    }

    /**
     * @dev set minterToAmountMinted mapping
     */
    function setMinterToAmountMinted(address minter, uint16 amount) external onlyOwner {
        minterToAmountMinted[minter] = amount;
    }

}