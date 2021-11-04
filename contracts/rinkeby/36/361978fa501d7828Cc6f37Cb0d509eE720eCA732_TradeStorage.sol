// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract TradeStorage {
    
    struct Proof {
        uint[2]  pi_a;
        uint[2][2]  pi_b;
        uint[2]  pi_c;
    }
    
    struct Signal {
        uint blockNumber;
        string hash;
    }
    
    struct PeriodProof {
        uint yield;
        Proof proof;
        uint blockNumber;
        string newBalanceHash;
    }
    
    address[] public traders;
    mapping(address => Signal[]) public signals;
    mapping(address => PeriodProof[]) public periodProofs;
    mapping(address => string) public names;
    
    
    function newTrader(string calldata email) external {
        traders.push(msg.sender);
        names[msg.sender] = email;
    }
    
    function addSignal(string calldata newSinal) external {
        Signal memory sig = Signal(block.number, newSinal);
        signals[msg.sender].push(sig);
    }
    
    function addPeriodProof(uint256 yield, Proof calldata proof, string calldata balanceHash, uint256 blockNumber) external {
        PeriodProof memory pr = PeriodProof(yield, proof, blockNumber, balanceHash);
        periodProofs[msg.sender].push(pr);
    }
    
    function getTradeLen(address trader) external view returns(uint) {
        return signals[trader].length;
    }
    
    function getProofLen(address trader) external view returns(uint) {
        return periodProofs[trader].length;
    }
    
    function getTradersCount() external view returns(uint) {
        return traders.length;
    }
    
    // for demo
    function changeTradeTime(address trader, uint tradeId, uint tradeBlock) external {
        signals[trader][tradeId].blockNumber = tradeBlock;
    }
    
}