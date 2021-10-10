/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LiquiSpin {
    
    using SafeMath for uint;
    
    struct Params {
        uint count;
        uint ticketPrice;
        uint ticketOrder;
        uint winnerPrize;
        uint looserStake;
    }
    
    struct Spin {
        address spinner;
        uint ticket;
        uint result;
        uint count;
        uint prize;
        uint timestamp;
    }
    
    address dev;
    Params params;
    uint pendingHarvest;
    
    Spin[] public spins;
    mapping(address => Spin[]) public winners;
    mapping(address => Spin[]) public loosers;

    event Looser(address sender, uint num, uint result, uint count);
    event Winner(address sender, uint won, uint result, uint count);
    event Harvest(uint amount);
    event Supply(uint amount);

    modifier onlyAccount {
        require(msg.sender == tx.origin, 'forbidden');
        _;
    }
    
    constructor(uint ticketPrice, uint ticketOrder, uint winnerPrize, uint looserStake) {
        dev = msg.sender;
        params.ticketPrice = ticketPrice;
        params.ticketOrder = ticketOrder;
        params.winnerPrize = winnerPrize;
        params.looserStake = looserStake;
    }
    
    // VIEW
    ////////////////////////////////////////////////////////////////////////////////////////////
    function paramsInfo() public view returns(Params memory) {
        return params;
    }
    
    function fetchSpins(uint offset, uint count) public view returns (Spin[] memory result){
        result = new Spin[](count);
        count = 0;
        for(uint i = offset; i < spins.length; i++) {
            result[count++] = spins[spins.length - i - 1];
            if(count == result.length) break;
        }            
    }
    
    function filterSpins(uint offset, uint count, bool won) public view returns(Spin[] memory filtered) {
        filtered = new Spin[](count);
        count = 0;
        for(uint i = offset; i < spins.length; i++) {
            if(spins[spins.length - i - 1].result == spins[spins.length - i - 1].ticket) {
                if(won) filtered[count++] = spins[spins.length - i - 1];
            } else {
                if(!won) filtered[count++] = spins[spins.length - i - 1];
            }
            if(count == filtered.length) break;
        }
    }
    
    function spinsCount() public view returns(uint) {
        return spins.length;
    }
    
    function userSpinsCount(address user) public view returns(uint won, uint lost) {
        return (winners[user].length, loosers[user].length);
    }
    
    function nextPrize() public view returns (uint) {
        uint winPrize = params.winnerPrize.add(params.looserStake*params.count);
        if(address(this).balance < winPrize) return 0;
        return winPrize;
    }
    
    // PUBLIC
    ////////////////////////////////////////////////////////////////////////////////////////////
    function supply() payable public {
        require(msg.sender == dev, 'forbidden');
        if(msg.value == 0) {
            payable(dev).transfer(pendingHarvest);
            emit Harvest(pendingHarvest);
            pendingHarvest = 0;
        } else {
            emit Supply(msg.value);
        }
    }

    receive() external payable onlyAccount {
        params.count++;
        require(nextPrize() > 0, 'participation disabled');
        require(msg.value >=  params.ticketPrice, 'Low ticketPrice');
        uint ticket = msg.value % 10**params.ticketOrder;
        uint result = uint256(keccak256(abi.encodePacked(
            uint256(keccak256(abi.encodePacked(msg.sender))) / block.timestamp +
            block.timestamp + block.difficulty + block.gaslimit + block.number +
            uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp
        ))) % 10**params.ticketOrder;
        Spin memory spin = Spin(msg.sender, ticket, result, params.count, 0, block.timestamp);
        if(ticket == result) {
            params.count = 0;
            spin.prize = params.winnerPrize + params.looserStake*spin.count;
            payable(spin.spinner).transfer(spin.prize);
            winners[spin.spinner].push(spin);
            emit Winner(spin.spinner, spin.prize, spin.result, spin.count);
        } else {
            loosers[msg.sender].push(spin);
            pendingHarvest = pendingHarvest.add(params.ticketPrice.sub(params.looserStake));
            emit Looser(spin.spinner, spin.ticket, spin.result, spin.count);
        }
        spins.push(spin);
        uint left = msg.value.sub(params.ticketPrice);
        if(left > 0) {
            payable(msg.sender).transfer(left);
        }
    }
}