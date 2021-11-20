/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IErc20Contract {
    function transferPresale(address recipient, uint amount) external returns (bool);
}

contract LoaPreSale {
    // Amounts
    uint public constant _minimumDepositBNBAmount = 0.005 ether; // Minimum deposit is 0.005 BNB
    uint public constant _bnbAmountCap = 1 ether; // Allow cap at 156.25 BNB, return the remaining amount back to the deposit address
    uint public constant _dailyRewardPerBnb = 64; // Every day 156.25 * 64 = 10,000 sent

    // Dates
    uint public constant _NOV_21_2021_00_00_00 = 1_637_397_746; // Presale starts at Nov 21 2021 8am Malaysian time
    uint public constant _NOV_22_2021_00_00_00 = 1_637_539_200; // Presale ends at Nov 22 2021 8am Malaysian time
    uint public constant _DEC_12_2021_00_00_00 = 1_637_397_746; // First distribution starts at DEC 12 2021 8am Malaysian time
    uint public constant _JUN_29_2022_23_59_59 = 1_656_460_800 + 86_399; // Final distribution ends at end of JUNE 30 2022 7:59:59am Malaysian time

    bool public _shouldPresaleEndEarlier; // Has Admin decided to end the Presale earlier?

    // Addresses
    address public _admin; // Admin address
    address public _erc20Contract; // External erc20 contract

    // Deposit variables
    uint public _totalAddressesDepositAmount; // Total addresses' deposit amount
    uint public _depositAddressesNumber;  // Number of deposit addresses

    mapping(uint => address) public _depositAddresses; // Deposit addresses
    mapping(address => bool) public _depositAddressesStatus; // Deposit addresses' whitelist status
    mapping(address => uint) public _depositAddressesBNBAmount; // Address' deposit amount

    uint public _startDepositAddressIndex;  // start ID of deposit addresses list
    mapping(address => uint) public _depositAddressesAwardedErc20CoinAmount; // Awarded ERC20 coin amount for a day of an address
    mapping(address => uint) public _depositAddressesAwardedErc20CoinIndex; // Awarded ERC20 coin index for a day of an address

    constructor(address erc20Contract) {
        _admin = msg.sender;
        _erc20Contract = erc20Contract;
    }

    // Modifier
    modifier onlyAdmin() {
        require(_admin == msg.sender);
        _;
    }

    // Events
    event Deposit(address indexed _from, uint _value);
    event NotRefund(address user, uint amount);

    // Transfer ownership
    function transferOwnership(address payable admin) external onlyAdmin {
        require(admin != address(0), "Zero address");
        _admin = admin;
    }

    // Add deposit addresses and whitelist them
    function addDepositAddress(address[] calldata depositAddresses) external onlyAdmin {
        
        uint depositAddressesNumber = _depositAddressesNumber;
        for (uint i = 0; i < depositAddresses.length; i++) {
            require(!_isContract(depositAddresses[i]), 'Contracts are not allowed');
            if (!_depositAddressesStatus[depositAddresses[i]]) {
                _depositAddresses[depositAddressesNumber] = depositAddresses[i];
                _depositAddressesStatus[depositAddresses[i]] = true;
                depositAddressesNumber++;
            }
        }
        _depositAddressesNumber = depositAddressesNumber;
    }

    function _isContract(address addr) internal view returns (bool) { uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    // Remove deposit addresses and unwhitelist them
    // number - number of addresses to process at once
    function removeAllDepositAddress(uint number) external onlyAdmin {
        require(block.timestamp < _NOV_21_2021_00_00_00, "Presale already started");
        uint i = _startDepositAddressIndex;
        uint last = i + number;
        if (last > _depositAddressesNumber) last = _depositAddressesNumber;
        for (; i < last; i++) {
            _depositAddressesStatus[_depositAddresses[i]] = false;
            _depositAddresses[i] = address(0);
        }
        _startDepositAddressIndex = i;
    }

    // Receive BNB deposit
    receive() external payable {
        require(block.timestamp >= _NOV_21_2021_00_00_00 && block.timestamp <= _NOV_22_2021_00_00_00,
            'Deposit rejected, presale has either not yet started or not yet overed');
        require(!_shouldPresaleEndEarlier, 'Admin has ended presale earlier');
        require(_depositAddressesStatus[msg.sender], 'Deposit rejected, deposit address is not yet whitelisted');
        require(msg.value >= _minimumDepositBNBAmount, 'Deposit rejected, it is lesser than minimum amount');

        _depositAddressesBNBAmount[msg.sender] = _depositAddressesBNBAmount[msg.sender] + msg.value;
        _totalAddressesDepositAmount = _totalAddressesDepositAmount + msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // Return leftOver BNB
    // number - number of addresses to process at once
    function returnBNB(uint number) external{
        require(block.timestamp > _NOV_22_2021_00_00_00 || _shouldPresaleEndEarlier , 'Presale has not yet overed');
        // use local variables to reduce gas usage
        uint totalAddressesDepositAmount = _totalAddressesDepositAmount;
        uint leftOverBNBBalance = totalAddressesDepositAmount - _bnbAmountCap;
        uint i = _startDepositAddressIndex;
        uint last = i + number;
        if (last > _depositAddressesNumber) last = _depositAddressesNumber;
        require(i < last, "Already returned");
        for (; i < last; i++) {
            address depositor = _depositAddresses[i];
            uint deposited = _depositAddressesBNBAmount[depositor];
            uint giveBackBNBAmount = deposited * leftOverBNBBalance / totalAddressesDepositAmount;
            if (giveBackBNBAmount != 0) {
                bool success = payable(depositor).send(giveBackBNBAmount);
                if (!success) emit NotRefund(depositor, giveBackBNBAmount);
            }
            uint contributedAmount = deposited * _bnbAmountCap / totalAddressesDepositAmount;
            _depositAddressesAwardedErc20CoinAmount[depositor] = _depositAddressesAwardedErc20CoinAmount[depositor] + contributedAmount * _dailyRewardPerBnb;
        }
        _startDepositAddressIndex = i;
    }

    // What is the date number? Start from 0 to 199. For eg: _distributeDatesNo = 0 for 12 DEC 2021
    function _distributeDatesNo(uint timestamp) public pure returns(uint) {
        if (timestamp < _DEC_12_2021_00_00_00 || timestamp >= _DEC_12_2021_00_00_00 + 86_400 * 200) return 0;
        return (timestamp - _DEC_12_2021_00_00_00) / 86_400;
    }
    // Main distribution logic
    function distribute() external {
        require(block.timestamp >= _DEC_12_2021_00_00_00, 'Distribute should be allowed after 12 DEC 2021');
        require(_startDepositAddressIndex == _depositAddressesNumber, "returnBNB should be called before");

        uint currentTimestamp = block.timestamp;

        if(currentTimestamp > _JUN_29_2022_23_59_59){
            currentTimestamp = _JUN_29_2022_23_59_59;
        }

        // use local variables to reduce the gas usage
        uint depositAddressesAwardedErc20CoinAmount = _depositAddressesAwardedErc20CoinAmount[msg.sender];
        uint depositAddressesAwardedErc20CoinIndex = _depositAddressesAwardedErc20CoinIndex[msg.sender];
        uint currentTimestampNo = _distributeDatesNo(currentTimestamp) + 1;
        uint dayNumberToClaimErc20Coin = currentTimestampNo - depositAddressesAwardedErc20CoinIndex;

        if (depositAddressesAwardedErc20CoinAmount > 0 && dayNumberToClaimErc20Coin > 0) {
            uint totalDailyAwardedErc20CoinAmount = depositAddressesAwardedErc20CoinAmount * dayNumberToClaimErc20Coin;

            if(totalDailyAwardedErc20CoinAmount > 0) {
                IErc20Contract erc20Contract = IErc20Contract(_erc20Contract);
                bool canTransferred = erc20Contract.transferPresale(msg.sender, totalDailyAwardedErc20CoinAmount);

                if(canTransferred) {
                    _depositAddressesAwardedErc20CoinIndex[msg.sender] = currentTimestampNo;
                }
            }
        }
    }

    // Allow admin to end presale earlier
    function endPreSaleEarlier() external onlyAdmin {
        _shouldPresaleEndEarlier = true;
    }

    // Allow admin to withdraw all the deposited BNB
    function withdrawAll() external onlyAdmin {
        payable(_admin).transfer(address(this).balance);
    }
}