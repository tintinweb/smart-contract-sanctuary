/**+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            abcLotto: a Block Chain Lottery

                            Don&#39;t trust anyone but the CODE!
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
 
/*
    address resolver for resolve 2 contracts interract.
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    depoly on:
    1) ropsten 
        owner:      0xB75272AE32a7BcE31C626cDb32d4b225f6974374
        address:    0xad90a7e8f87739c56549885fa47520719bbc8cc1
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
pragma solidity ^0.4.18;
contract abcLottoResolver {
    address addr;
    address controllerAddr;
    address wallet;
    address owner;

    function abcLottoResolver() public{
        owner = msg.sender;
    }

    function setNewOwner(address newOwner) public{
        require(msg.sender == owner);
        require(newOwner != address(0x0));
        owner = newOwner;
    }

    function getAddress() public view returns (address) {
        return addr;
    }

    function setAddress(address newAddr) public{
        require(msg.sender == owner);
        require(newAddr != address(0x0));
        addr = newAddr;
    }

    function getControllerAddress() public view returns (address) {
        return controllerAddr;
    }

    function setControllerAddress(address newAddr) public{
        require(msg.sender == owner);
        require(newAddr != address(0x0));
        controllerAddr = newAddr;
    }

    function getWalletAddress() public view returns (address) {
        return wallet;
    }

    function setWalletAddress(address newAddr) public{
        require(msg.sender == owner);
        require(newAddr != address(0x0));
        wallet = newAddr;
    }
}