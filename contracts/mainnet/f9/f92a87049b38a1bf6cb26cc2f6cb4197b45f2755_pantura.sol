pragma solidity ^0.4.24;

contract pantura {
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
    
    function pantura() {
        add1 = 0xfF48aF51938f44E25e658D14A5C4a6f7b3Ea880C;
        add2 = 0x005953b57BbeD3c37bf4bE2d07fc0950E670B086;
        add3 = 0x0f98ad599D373E0f3Ce5ec83a74b303491A67fA3;
        add4 = 0xC4A091b0ABE06dD96f98af5FaAD7e504D25Bb9AD;
        add5 = 0x80f7cA47C577FdaDc6781073E1D457b98Fc16e97;
        add6 = 0xc5Af5d85119905B24E76A81D0c8Ad9FC12F8815D;
        add7 = 0xf88BB479b9065D6f82AC21E857f75Ba648EcBdA7;
        add8 = 0x6E204E498084013c1ba4071D7d61074467378855;
        add9 = 0x2bC86DE64915873A8523073d25a292E204228156;
        add10 = 0x6E204E498084013c1ba4071D7d61074467378855;
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