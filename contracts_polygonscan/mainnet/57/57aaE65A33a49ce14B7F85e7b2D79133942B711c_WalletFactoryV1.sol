//SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./CustomerWalletV1.sol";


interface FiskPayFactoryInterface{

    function AddNewWallet(address _walletAddress, address _ownerAddress) external returns(bool);
    function GetFactoryAddress() external view returns(address);
    function CanCreateWallet(address _senderAddress) external view returns(bool);
}

contract WalletFactoryV1{

    address constant private fiskPayAddress = 0xaBE9255A99fd2EFB4a15fcF375E5D3987E32Ad74;

    FiskPayFactoryInterface constant private fisk = FiskPayFactoryInterface(fiskPayAddress);

    bool private isCreating = false;

    event WalletAddress(address _walletAddress);

    function CreateWalletContract() external returns(bool){

        require(!isCreating);
        require(fisk.GetFactoryAddress() == address(this), "Contract factory deprecated");
        require(fisk.CanCreateWallet(msg.sender), "You can mint a wallet approximately every 24 hours");

        uint32 size;
        address sender = msg.sender;

        assembly {

            size := extcodesize(sender)
        }

        require(size == 0, "Contracts are not allowed to create wallets");

        CustomerWalletV1 newWalletContract = new CustomerWalletV1(fiskPayAddress);

        isCreating = true;

        require(fisk.AddNewWallet(address(newWalletContract), msg.sender), "Wallet could not be logged");

        isCreating = false;
        
        emit WalletAddress(address(newWalletContract));
        
        return true;
    }

    function FactoryVersion() external pure returns(string memory){
        
        return "v1.0";
    }

    receive() external payable{
        
        revert();
    }

    fallback() external payable{
        
        revert();
    }
}