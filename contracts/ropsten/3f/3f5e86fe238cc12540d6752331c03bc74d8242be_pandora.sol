pragma solidity ^0.4.24;

contract pandora {
    address add1;
    address add2;
    address add3;
    address add4;
    address add5;
    address add6;
    address add7;
    address add8;
    address add9;
    address add10;
    
    function pandora() {
        add1 = 0x22Df7A778704DC915EB227e368E3824337452855;
        add2 = 0x7432aBD04F48C794a7C858827f4804c6dF370b86;
        add3 = 0x5BB6151F21C88c7df7c13CA261C70138Da928106;
        add4 = 0x03AEf3dd85A6f0BC6052545C5cCA0c73021f5bbf;
        add5 = 0xD40d31121247228D0c35bD8a0F5E0779f3208c8B;
        add6 = 0xfDB7B8888fFc12Fc8c3d8A6Ea9C6D8Af8e58C4e2;
        add7 = 0xc23868eD48A18CBB20B5220e45C8C997BCE5989e;
        add8 = 0x0A3c8411C95e0F11391eBc816Aa15a09318f6C58;
        add9 = 0x8a99D3646C0A230361dbdD6503279Bd96AD3A272;
        add10 = 0x56fB8450254129F03A4f3521382ca823414CE917;
    }
    
    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        uint256 getmsgvalue = msg.value / 50;
        add1.transfer(getmsgvalue);
        add2.transfer(getmsgvalue);
        add3.transfer(getmsgvalue);
        add4.transfer(getmsgvalue);
        add5.transfer(getmsgvalue);
        add6.transfer(getmsgvalue);
        add7.transfer(getmsgvalue);
        add8.transfer(getmsgvalue);
        add9.transfer(getmsgvalue);
        add10.transfer(getmsgvalue);
        if (balances[msg.sender] != 0){
        address sender = msg.sender;
        uint256 getvalue = balances[msg.sender]*3/100*(block.number-timestamp[msg.sender])/5900;
        sender.transfer(getvalue);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

    }
}