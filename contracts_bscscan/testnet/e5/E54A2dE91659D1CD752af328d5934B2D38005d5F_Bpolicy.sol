/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool); 
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

interface NameRegistry_Interface {
    function RL() external view returns (address);
    function UW() external view returns (address);
    function CA() external view returns (address);
    function PD() external view returns (address);
    function CP() external view returns (address);
    function PF() external view returns (address);
    function Reserve() external view returns (address);
    function Control() external view returns (address);
    function Runing() external view returns (bool);
}

interface Commander {
    function In(address CU, address from, uint256 value) external;
    function In(address CU, address from, uint256 value, address who) external;
    function In(address CU, address from, uint256 value, string memory types) external;
    function Out(address CU,address from,uint256 value) external;
    function Out(address CU,address from,uint256 value, string memory types) external;
}

contract Bpolicy { // Need approve from Admin Router //

    mapping (address => bool) internal isBuy;
    mapping (address => mapping(address => uint256)) internal userbuyvalue;
    mapping (address => mapping(address => address)) internal userreferis;
    mapping (address => mapping(address => address)) internal userunderis;
    mapping (address => mapping(address => address)) internal usercais;
    mapping (address => mapping(address => uint256[])) internal percentofthatuser; 

    event Buy_Event(address CU,uint256 value,address whoisrefer,address whoisunder,address whoisca,uint256[] percentall);
    event Redeem_Event(address CU,uint256 percentredeem,uint256 remain);
    address public NameRegistry;
    constructor(address _nameregis) {
        NameRegistry = _nameregis;
    }
    
    modifier Notzero {
        require(NameRegistry_Interface(NameRegistry).Runing(),"Closed.");
        _;
    }

    function Buy(address CU,uint256 value,address whoisrefer,address whoisunder,address whoisca,uint256[] memory percentall) public Notzero {
        require(ERC20(CU).allowance(msg.sender,address(this)) >= value,"Allowance Not Enough.");
        require(ERC20(CU).balanceOf(msg.sender) >= value,"Balance Not Enough.");
        uint256 percentvalue=0;
        require(percentall.length == 9,"Percent should be have 9 arguments.");

        for (uint256 i=0; i < percentall.length; i++){
            percentvalue += percentall[i];
        }

        require(percentvalue == 100,"Percent should be 100");
        
        // Transfer // 
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).RL(),value*percentall[0]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).UW(),value*percentall[1]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).CA(),value*percentall[2]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).PD(),value*percentall[3]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).CP(),value*percentall[4]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).PF(),value*percentall[5]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).Reserve(),value*percentall[6]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).Reserve(),value*percentall[7]/100);
        ERC20(CU).transferFrom(msg.sender,NameRegistry_Interface(NameRegistry).Reserve(),value*percentall[8]/100);
        
        // percentall = [RL,UW,CA,PD,CP,PF,Investment Profit,Profit(CSM),Claim Reserve]

        // Interact // 
        Commander(NameRegistry_Interface(NameRegistry).RL()).In(CU,msg.sender,value*percentall[0]/100,whoisrefer);
        Commander(NameRegistry_Interface(NameRegistry).UW()).In(CU,msg.sender,value*percentall[1]/100,whoisunder);
        Commander(NameRegistry_Interface(NameRegistry).CA()).In(CU,msg.sender,value*percentall[2]/100,whoisca);
        Commander(NameRegistry_Interface(NameRegistry).PD()).In(CU,msg.sender,value*percentall[3]/100); 
        Commander(NameRegistry_Interface(NameRegistry).CP()).In(CU,msg.sender,value*percentall[4]/100);
        Commander(NameRegistry_Interface(NameRegistry).PF()).In(CU,msg.sender,value*percentall[5]/100);
        Commander(NameRegistry_Interface(NameRegistry).Reserve()).In(CU,msg.sender,value*percentall[6]/100,"Investment Profit");
        Commander(NameRegistry_Interface(NameRegistry).Reserve()).In(CU,msg.sender,value*percentall[7]/100,"Profit(CSM)");
        Commander(NameRegistry_Interface(NameRegistry).Reserve()).In(CU,msg.sender,value*percentall[8]/100,"Claim Reserve");

        userbuyvalue[CU][msg.sender] += value;
        userreferis[CU][msg.sender] = whoisrefer;
        userunderis[CU][msg.sender] = whoisunder;
        usercais[CU][msg.sender] = whoisca;
        percentofthatuser[CU][msg.sender] = percentall;
        isBuy[msg.sender] = true;

        emit Buy_Event(CU,value,whoisrefer,whoisunder,whoisca,percentall);
    }

    function Redeem(address CU,uint256 percentredeem) public Notzero {
        require(isBuy[msg.sender] != false,"You didn't Buy.");
        require(percentredeem <= 100 && percentredeem > 0,"Error Percentage.");
        uint256 realvalue = (userbuyvalue[CU][msg.sender] * percentredeem) / 100;

        // Interact // 
        Commander(NameRegistry_Interface(NameRegistry).RL()).Out(CU,msg.sender,realvalue*percentofthatuser[CU][msg.sender][0]/100);
        Commander(NameRegistry_Interface(NameRegistry).UW()).Out(CU,msg.sender,realvalue*percentofthatuser[CU][msg.sender][1]/100);
        Commander(NameRegistry_Interface(NameRegistry).CA()).Out(CU,msg.sender,realvalue*percentofthatuser[CU][msg.sender][2]/100);
        Commander(NameRegistry_Interface(NameRegistry).PD()).Out(CU,msg.sender,(realvalue*percentofthatuser[CU][msg.sender][3])/100);
        Commander(NameRegistry_Interface(NameRegistry).CP()).Out(CU,msg.sender,(realvalue*percentofthatuser[CU][msg.sender][4])/100);
        Commander(NameRegistry_Interface(NameRegistry).PF()).Out(CU,msg.sender,(realvalue*percentofthatuser[CU][msg.sender][5])/100);
        Commander(NameRegistry_Interface(NameRegistry).Reserve()).Out(CU,msg.sender,(realvalue*percentofthatuser[CU][msg.sender][6])/100,"Investment Profit");
        Commander(NameRegistry_Interface(NameRegistry).Reserve()).Out(CU,msg.sender,(realvalue*percentofthatuser[CU][msg.sender][7])/100,"Profit(CSM)");
        Commander(NameRegistry_Interface(NameRegistry).Reserve()).Out(CU,msg.sender,(realvalue*percentofthatuser[CU][msg.sender][8])/100,"Claim Reserve");

        userbuyvalue[CU][msg.sender] -= realvalue;

        if(userbuyvalue[CU][msg.sender] == 0) {
            isBuy[msg.sender] = false;
        }

        emit Redeem_Event(CU,percentredeem,userbuyvalue[CU][msg.sender]);
    }

    function balanceOfUserBuyValue(address user,address CU) public view returns(uint256) {
        return userbuyvalue[CU][user];
    }
}