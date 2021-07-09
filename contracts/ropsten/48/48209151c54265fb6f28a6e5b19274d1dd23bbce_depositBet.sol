/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity 0.8.4;

//Property of Fey. Version 1.0.3.

contract depositBet {
    address payable public agent;
    
    mapping(address => uint256) public REDbalance;
    mapping(address => uint256) public BLKbalance;
    address payable[] public ownerRED;
    address payable[] public ownerBLK;
    uint256 public REDcount;
    uint256 public BLKcount;
    uint256 public contratcBalanceRED;
    uint256 public contratcBalanceBLK;
    uint256 public etherSupply;
    uint256 public result;
    
    event depositRED(address user, uint256 amount);
    event depositBLK(address user, uint256 amount);
    event RewardSended(address winner, uint256 amount);
    
    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }
    
    modifier NoZeroBalances() {
        require (contratcBalanceRED != 0);
        require (contratcBalanceBLK != 0);
        _;
    }
    
    constructor() {
        agent = payable(msg.sender);
    }
    
    function betOnRED() payable public {
        REDbalance[msg.sender] += msg.value;
        contratcBalanceRED += msg.value;
        ownerRED.push(payable(msg.sender));
        REDcount++;
        emit depositRED(msg.sender,msg.value);
        etherSupply += msg.value;
    }
    
    function betOnBLK() payable public {
        BLKbalance[msg.sender] += msg.value;
        contratcBalanceBLK += msg.value;
        ownerBLK.push(payable(msg.sender));
        BLKcount++;
        emit depositBLK(msg.sender,msg.value);
        etherSupply += msg.value;
    }
    
    function Run(uint256 seed) public onlyAgent NoZeroBalances returns (uint256){
        uint256 x = block.timestamp + seed;
        uint256 i;
        uint256 r;
        uint256 reward;
        
        if(x % 2 == 0){ //RED wins
            result = 0;
        
            for(i=0; i<REDcount; i++){
                if(REDbalance[ownerRED[i]] != 0){
                    r = contratcBalanceRED / REDbalance[ownerRED[i]];
                    reward = ( (contratcBalanceBLK + contratcBalanceRED) / r ) * 9 ;
                    ownerRED[i].transfer( reward / 10 );
                    REDbalance[ownerRED[i]] = 0;
                    etherSupply -= reward / 10;
                    emit RewardSended(ownerRED[i],reward);
                }
            }
            
            for(i=0; i<BLKcount; i++){
                BLKbalance[ownerBLK[i]] = 0;
            }
            contratcBalanceBLK = 0;
            contratcBalanceRED = 0;
            REDcount = 0;
            BLKcount = 0;
            delete ownerBLK;
            delete ownerRED;
        }
        
        if( x % 2 == 1){ //BLK wins
            result = 1;
            
            for(i=0; i<BLKcount; i++){
                if(BLKbalance[ownerBLK[i]] != 0){
                    r = contratcBalanceBLK / BLKbalance[ownerBLK[i]];
                    reward = ( (contratcBalanceBLK + contratcBalanceRED) / r ) * 9;
                    ownerBLK[i].transfer( reward / 10 );
                    BLKbalance[ownerBLK[i]] = 0;
                    etherSupply -= reward / 10;
                    emit RewardSended(ownerBLK[i],reward);
                }
            }
            
            for(i=0; i<REDcount; i++){
                REDbalance[ownerRED[i]] = 0;
            }
            contratcBalanceBLK = 0;
            contratcBalanceRED = 0;
            REDcount = 0;
            BLKcount = 0;
            delete ownerBLK;
            delete ownerRED;
        }
        return result;
    }
    
    function withdraw() onlyAgent public {
        agent.transfer((etherSupply*9) / 10);
        etherSupply -= (etherSupply*9) / 10;
    }
}