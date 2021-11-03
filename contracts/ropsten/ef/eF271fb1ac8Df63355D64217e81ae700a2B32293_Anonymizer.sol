/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

contract Anonymizer {
    /**
     * @notice Contract owner:
     * can upgrade contracts
     * can pause/freeze contracts in case of emergency
     * can't access users funds
     **/
    address public owner;

    /**
     * @dev users balances:
     * The key is the user's address(hashed to increase privacy)
     * The value is the user's balance
     **/
    mapping(address => uint256) private balances;

    /**
     * @dev events:
     * @param balance the updated eth balance for current user
     **/
    event EthDeposit(uint256 indexed balance);
    event EthWithdraw(uint256 indexed balance);

    /**
     * @dev initialize contract owner
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Returns the ether balance available inside the contract
     * @return user's contract balance
     **/
    function getBalance(address _addr) public view returns (uint256) {
        return balances[_addr];
    }

    /**
     * @dev increase the user's contract balance
     * @return user's updated balance
     **/
    function depositEth() public payable returns (uint256) {
        balances[msg.sender] += msg.value;
        emit EthDeposit(balances[msg.sender]);
        return balances[msg.sender];
    }

    /**
     * @dev decrease the user's contract balance
     * @return user's updated balance
     **/
    function withdrawEth(address payable _to, uint256 _amount)
        public
        returns (uint256)
    {
        require(balances[msg.sender] >= _amount, "Insufficient funds.");

        // the recommanded way to send ether after December 2019(but errors out, probably due to solidity version)
        // (bool sent, ) = _to.call{value: _amount}("");
        // require(sent, "Failed to send Ether");

        balances[msg.sender] -= _amount;
        _to.transfer(_amount);
        // require(sent, "Failed to send Ether");
        emit EthWithdraw(balances[msg.sender]);
        return balances[msg.sender];
    }

    /**
     * @notice Send ether to an address(including yourself)
     * @notice By sending funds to your own address, the funds are kept within the contract and available for later use
     * @notice By keeping funds into the contract, it increases the transaction privacy but the risk as well
     * @notice DO NOT KEEP LARGE AMOUNTS INTO THE CONTRACT
     * @dev send ether to provided address and/or increase user's contract balance
     * @param _to the destination address to which the ether is sent
     * @param _amountToSend the amount of ether sent to the provided address
     * @param _amountToDeposit the amount of ether to deposit into the contract. Can be zero.
     * @return user's contract balance
     **/
    function sendEther(
        address _to,
        uint256 _amountToSend,
        uint256 _amountToDeposit
    ) external payable returns (uint256) {}

    /**
     * @dev increase the user's contract balance
     * @param _amount the amount to be added to the user's balance
     * @return user's contract balance
     **/
    function depositToInternalAccount(uint256 _amount)
        private
        returns (uint256)
    {}

    /**
     * @dev decrease user's contract balance
     * @param _amount the amount to be substracted from the user's balance
     * @return user's contract balance
     **/
    function substractFromInternalAccount(uint256 _amount)
        private
        returns (uint256)
    {}

    /**
     * @dev send ether to an external account
     * @param _to the external account address
     * @param _amount the amount sent to external address
     * @return transaction success/failure
     **/
    function sendToExternalAccount(address _to, uint256 _amount)
        private
        returns (bool)
    {}
}