/**
 *Submitted for verification at FtmScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct battleAtrribute {      
        uint32 health;
        uint32 damage;    
}
    
interface rarity {
    function ownerOf(uint) external view returns (address);
}

interface vine {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address) external returns (uint256) ;
}

interface eGold {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address) external returns (uint256) ;
}

interface rockTicket {
    function mint(address dst, uint256 amount) external;
}

interface healthAndDamage {
    function reset(uint _summoner) external returns (battleAtrribute calldata);
    function increase(uint _summoner, uint32 _health, uint32 _damage) external;
}

contract duel {
    address ownerAddress;
    constructor(){
	    ownerAddress = msg.sender;
    }

    struct state {      
        uint winner;
        uint loser; 
        bool flag; // false is Waiting,true is over.
    } 

    uint public chip = 1e18;
    uint public reward = 2*(chip - chip/10); 
    uint public total;
    mapping(uint => state) public states;
    mapping(uint => uint32) public num;
    address private AAddress;
    address private BAddress;
    uint private ASummoner;
    uint32 private AHealth;
    uint32 private ADamage;
    uint32 private ARandom;

    
    rarity constant rm = rarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    vine constant vi = vine(0xa1f9c51aA57c8bb4a71eDce0BacE1473dF10c712);
    eGold constant eG = eGold(0x38C6eE8BaFCe7858F5E0B1913eED74534a8D1E27);
    rockTicket constant rockT = rockTicket(0xc766Ab906F8880FA6bff040a73fC9891214fAb49);
    healthAndDamage constant hd = healthAndDamage(0x28711B3A796FE33Ba260299f7Fb95f39214B2584);
    
    modifier onlyOwner() {
        require(ownerAddress == msg.sender, "duel: caller is not the owner");
        _;
    }
    
    function setChip(uint _chip) external onlyOwner {
        chip = _chip;
    }
    
    function joinDuel(uint summoner, uint32 random) external {
        require(rm.ownerOf(summoner) == msg.sender, "Not owner");
        require(AAddress==address(0) || BAddress==address(0), "Waiting for next round");
        
        vi.transferFrom(msg.sender, address(this), chip);
        eG.transferFrom(msg.sender, address(0), 100e18);
        battleAtrribute memory ba = hd.reset(summoner);

        
        if(AAddress !=address(0)) {
            BAddress = msg.sender;
            bool isAWin;
            uint32 r;
            (isAWin,r)= calc(AHealth, ADamage,ba.health, ba.damage, ARandom, random);
            if (isAWin) {
                vi.transfer(AAddress,reward);
                rockT.mint(AAddress,r);
                states[total].loser = summoner;

            } else {
                vi.transfer(BAddress,reward);
                rockT.mint(BAddress,r);
                states[total].winner = summoner;
                states[total].loser = ASummoner;
            }

            states[total].flag = true;
            num[ASummoner]++;
            num[summoner]++;
            hd.increase(ASummoner,1000/num[ASummoner], 100/num[ASummoner]);
            hd.increase(summoner,1000/num[summoner], 100/num[summoner]);
            AAddress = address(0);
            BAddress = address(0);
            
        } else {
            AAddress = msg.sender;
            ASummoner = summoner;
            AHealth = ba.health;
            ADamage = ba.damage;
            ARandom = random;
            total++;
            states[total].winner = ASummoner;
            states[total].flag = false;
        }
    }

    function calc(uint32 _AHealth, uint32 _ADamage, uint32 _BHealth, uint32 _BDamage, uint32 _ARandom, uint32 _BRandom) internal view returns(bool f,uint32 r) {
        uint32 a = _AHealth / _BDamage;
        uint32 b = _BHealth / _ADamage;
        r = roll(_ARandom,_BRandom);
        
        if (a > b) {_BDamage *= r;}
        if (a < b) {_ADamage *= r;}
        if (a == b) {_ADamage *= roll(r,_BRandom);_BDamage *=  roll(_ARandom,r);}
        a = _AHealth / _BDamage;
        b = _BHealth / _ADamage;
        if (a == b) {
            if (roll(0,0)%2 == 0) {a = b + 1;}
            else {b = a + 1;}
        }
        if (a > b) {f = true;}//A win.
        else {f = false;}
    }
    
    function isWaiting(address _address) external view returns(bool){
        if(AAddress == _address ){
            return true;
        }else{
            return false;
        }
    }
    
        
    function roll(uint _a, uint _b) public view returns (uint32){
        uint c = uint(keccak256(abi.encodePacked(block.timestamp, _a, _b)))%100 + 1;
        if (c > 40) { return 1;}
        else {return 100/uint32(c);}
        
    }
    
    function withdraw(address exchequer) external onlyOwner {
        vi.transfer(exchequer,vi.balanceOf(address(this)));
    }   

}