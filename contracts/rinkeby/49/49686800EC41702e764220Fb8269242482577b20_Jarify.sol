/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

abstract contract Context {
    function _sender() internal view returns (address) {
        return msg.sender;
    }

    function _value() internal view returns (uint256) {
        return msg.value;
    }


}

contract Fundable is Context {
    struct FundEntry {
        address addr;
        uint256 amount;
        uint256 time;
        uint256 block;
    }

    Jarify public jarify;
    address public owner;

    mapping(address => uint256) public addressToAmountFunded;
    FundEntry[] public fundEntries;

    uint256 public fundingTotal;
    uint256 public fundingGoal;
    bool public isClosed;
    bool public isWithdrawed;

    constructor(address _owner, Jarify _jarify) {
        owner = _owner;
        jarify = _jarify;
    }

    FundEntry[50] public topBalances;

    function elaborateTopX(address addr) private {
        uint256 donatedTotal = addressToAmountFunded[addr];

        uint256 currentPos = currentPosAtLeaderboard(addr);
        uint256 targetPos = targetPosAtLeaderboard(donatedTotal);
        bool isOnLeaderboard = targetPos < topBalances.length;
        bool isAlreadyOnLeaderboard = currentPos < topBalances.length;

        if (!isOnLeaderboard) {
            return;
        }

        bool isSameAsNow = currentPos == targetPos;

        if (isSameAsNow) {
            topBalances[currentPos].amount = donatedTotal;
            return;
        }

        if (isAlreadyOnLeaderboard) {
            // remove the current spot
            delete topBalances[currentPos];

            //currentPos = 1; targetPos = 0;
            // 0 => 1
            for (
                uint256 j = currentPos; /* 1 */
                j > 0;
                j--
            ) {
                topBalances[j].amount = topBalances[j - 1].amount;
                topBalances[j].addr = topBalances[j - 1].addr;
                topBalances[j].block = topBalances[j - 1].block;
                topBalances[j].time = topBalances[j - 1].time;
            }

            topBalances[targetPos].amount = donatedTotal;
            topBalances[targetPos].addr = addr;
            topBalances[targetPos].block = block.number;
            topBalances[targetPos].time = block.timestamp;
        } else {
            /** shift the array of position (getting rid of the last element) **/
            for (uint256 j = topBalances.length - 1; j > targetPos; j--) {
                topBalances[j].amount = topBalances[j - 1].amount;
                topBalances[j].addr = topBalances[j - 1].addr;
                topBalances[j].block = topBalances[j - 1].block;
                topBalances[j].time = topBalances[j - 1].time;
            }
            /** update the new max element **/
            topBalances[targetPos].amount = donatedTotal;
            topBalances[targetPos].addr = addr;
            topBalances[targetPos].block = block.number;
            topBalances[targetPos].time = block.timestamp;
        }
    }

    function currentPosAtLeaderboard(address addr)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < topBalances.length; i++) {
            if (topBalances[i].addr == addr) {
                return i;
            }
        }

        return topBalances.length;
    }

    function targetPosAtLeaderboard(uint256 donatedTotal)
        private
        view
        returns (uint256)
    {
        uint256 i = 0;
        /** get the index of the current max element **/
        for (i; i < topBalances.length; i++) {
            if (topBalances[i].amount < donatedTotal) {
                return i;
            }
        }

        return topBalances.length;
    }

    // ---

    modifier onlyOwner() {
        require(msg.sender == owner, "You need to be the owner");
        _;
    }

    modifier onlyWhenOpen() {
        require(isClosed == false, "Funding is closed");
        _;
    }

    modifier onlyWhenClosed() {
        require(isClosed == true, "Funding not closed");
        _;
    }

    function fund() public payable onlyWhenOpen {
        addressToAmountFunded[msg.sender] += msg.value;
        fundingTotal += msg.value;
        fundEntries.push(
            FundEntry(_sender(), _value(), block.timestamp, block.number)
        );
        elaborateTopX(msg.sender);
    }

    function close() public onlyOwner {
        isClosed = true;
    }

    function withdraw() public payable onlyOwner onlyWhenClosed {
        payable(msg.sender).transfer(address(this).balance);
        isWithdrawed = true;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getLatestFunds() external view returns (FundEntry[] memory) {
        FundEntry[] memory entries = getLatestFundsInt();
        uint256 fundersCount = entries.length;
        FundEntry[] memory result = new FundEntry[](fundersCount);

        for (uint256 i = 0; i < fundersCount; i++) {
            result[i] = entries[i];
        }
        return result;
    }

    function getTopFunders() external view returns (FundEntry[] memory) {
        uint256 fundersCount = topBalances.length;
        FundEntry[] memory result = new FundEntry[](fundersCount);

        for (uint256 i = 0; i < fundersCount; i++) {
            result[i] = topBalances[i];
        }
        return result;
    }

    function getLatestFundsInt() private view returns (FundEntry[] memory) {
        uint256 _length = fundEntries.length;
        uint256 _take = 5;

        if (_length < _take) {
            _take = _length;
        }

        if (_take <= 0) {
            return new FundEntry[](0);
        } else {
            FundEntry[] memory _funders = new FundEntry[](_take);

            for (uint256 i; i < _take; i++) {
                _funders[i] = fundEntries[_length - 1 - i];
            }

            return _funders;
        }
    }

    function getFundAmountOf(address _address) public view returns (uint256) {
        return addressToAmountFunded[_address];
    }
}

contract Jarify {
    mapping(address => Fundable) public authorizedContractAddresses;
    mapping(address => Fundable) public latestContract;

    uint256 public total;

    modifier onlyAuthorizedContract() {
        require(
            address(authorizedContractAddresses[msg.sender]) != address(0),
            "You are not an authorized contract"
        );
        _;
    }

    function create() public returns (address) {
        Fundable fundable = new Fundable(msg.sender, this);
        address _address = address(fundable);
        authorizedContractAddresses[_address] = fundable;
        latestContract[msg.sender] = fundable;
        return _address;
    }

    function getLatestContract() public view returns (address) {
        return address(latestContract[msg.sender]);
    }

    function increase(uint256 _amount) public onlyAuthorizedContract {
        total += _amount;
    }

    function isValid(address _address) public view returns (bool) {
        return address(authorizedContractAddresses[_address]) != address(0);
    }
}