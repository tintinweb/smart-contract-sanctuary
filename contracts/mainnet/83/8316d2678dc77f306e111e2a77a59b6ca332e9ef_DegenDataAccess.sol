/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.8.0;

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
----------       -----------    --------------   -----------    ------        ---
-----------      -----------    --------------   -----------    ---  --       --- 
---     -----    ---            ---              ---            ---   ---     ---
---     ------   -------        ---    -------   -------        ---    ---    ---
---     ------   -------        ---    -------   -------        ---     ---   ---
---     -----    ---            ---        ---   ---            ---      ---  ---
-----------      -----------    --------------   -----------    ---       --- ---  
----------       -----------    --------------   -----------    ---        ------
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     ----------              -----        -------------         -----
     -----------            --- ---       -------------        --- ---
     ---     -----         ---   ---           ---            ---   ---
     ---     ------       ---     ---          ---           ---     ---
     ---     ------      -------------         ---          -------------    
     ---     -----      ---------------        ---         ---------------
     -----------       ---           ---       ---        ---           ---
     ----------       ---             ---      ---       ---             ---
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
@Title DegenData Pro Degen Access Contract.
@Author DegenData.
@Notice DegenData.io access contract. 
*/
contract DegenDataAccess {
    //StateVariables
    address public owner;
    uint256 public registrationFee;
    address[] public addressList;

    //Customer Struct
    struct Customer {
        bool isPaid;
        uint256 expirationDate;
    }

    //Address to struct mapping for customers
    mapping(address => Customer) public UserRegistion;

    //@Dev Constructor setting intital owwner set to contract deployer & initializes regestration Fee to .069ETH.
    constructor() {
        owner = msg.sender;
        registrationFee = .069 ether;
    }

    //@Dev modifier: OnlyOwner requirement for admin functions.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner Can Perform this function");
        _;
    }

    //fallback
    fallback() external payable {
        revert();
    }

    //@dev returns the number customers that have subscribed.
    function getCustomerCount() public view returns (uint256) {
        return addressList.length;
    }

    //@dev customer registration function. Checks if customer exist first then adds to customers array. otherwai
    function register() public payable {
        require(msg.value >= registrationFee, "Insufficient funds sent");
        require(
            UserRegistion[msg.sender].isPaid == false,
            "You already registered you knucklehead"
        );

        if (UserRegistion[msg.sender].expirationDate == 0) {
            addressList.push(msg.sender);
            UserRegistion[msg.sender].isPaid = true;
            UserRegistion[msg.sender].expirationDate =
                block.timestamp +
                365 days;
        }

        if (
            UserRegistion[msg.sender].expirationDate > block.timestamp &&
            UserRegistion[msg.sender].isPaid == false
        ) {
            UserRegistion[msg.sender].isPaid = true;
            UserRegistion[msg.sender].expirationDate =
                block.timestamp +
                365 days;
        }
    }

    //@dev checks if a user is past their subscription expiration date.
    function userPastExpiration(address _address) public view returns (bool) {
        if (
            block.timestamp > UserRegistion[_address].expirationDate &&
            UserRegistion[_address].expirationDate != 0
        ) {
            return true;
        }
        return false;
    }

    // ADMIN FUNCTIONS
    // @dev sets new `owner` state variable. Granting new owner control to admin functions.
    // @param address.New address to be set.
    function setNewOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // @dev sets new `registrationFee` state variable. Owner can set access price.
    // @param  value to set new registration fee. Remember to set value to approiate decimal places. 1 ETH = 1000000000000000000, .069 ETH = 69000000000000000
    function setNewRegistrationPrice(uint256 _newFee) public onlyOwner {
        registrationFee = _newFee;
    }

    // @dev Will evaluate if an array of addresses are past their subscription date and set their payment status to false .
    // @param array of address.
    function resetUserPaidStatus(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            if (userPastExpiration(_address[i])) {
                UserRegistion[_address[i]].isPaid = false;
            }
        }
    }
    
     // @dev Will set their payment status to false .
    // @param address.
    function resetUserPaidFlag(address _address) public onlyOwner {
            UserRegistion[_address].isPaid = false;
    }

    //@Dev Allow Owner of the contract to withdraw the balances to themselves.
    function withdrawToOwner() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // @Dev Allow Owner of the contract to withdraw a specified amount to a different address.
    // @Notice Could be used for funding a DegenDao contract, another dApp, or gitcoin Grant.
    function withdrawToAddress(address _recipient, uint256 _amount)
        public
        onlyOwner
    {
        payable(_recipient).transfer(_amount);
    }
    

    //@Dev Allow owner of the contract to set an address to True in mapping without payment.
    function giveAccountAway(address _address) public onlyOwner {
        UserRegistion[_address].isPaid = true;
    }
}