pragma solidity ^0.8.6;

contract A {
    //если функции вызваны напрямую, то
    //msg.sender = tx.origin
    function getSender() public view returns (address) {
        return msg.sender;
    }

    function getOriginalSender() public view returns (address) {
        return tx.origin;
    }
}

contract B {
    A public a;

    constructor(address _a) {
        a = A(_a);
    }
    
    //sender = адрес контракта B если функция вызывается с контракта B и C
    function callContractA() public view returns (address sender, address origin) {
       return (a.getSender(), a.getOriginalSender());
    }

    function getSender() public view returns (address) {
        return msg.sender;
    }

    function getOriginalSender() public view returns (address) {
        return tx.origin;
    }
}

contract C {
    A public a;
    B public b;

    constructor(address _a, address _b) {
        a = A(_a);
        b = B(_b);
    }

    //sender = адрес контракта С
    function callContractA() public view returns (address sender, address origin) {
       return (a.getSender(), a.getOriginalSender());
    }

    //sender = адрес контракта B (вызов A через B)
    function callContractAfromB() public view returns (address sender, address origin) {
        return b.callContractA();
    }
    //sender = адрес контракта C
    function callContractB() public view returns (address sender, address origin) {
       return (b.getSender(), b.getOriginalSender());
    }
}

