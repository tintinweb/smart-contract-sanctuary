pragma solidity 0.4.18;




contract KyberNetworkENSResolver {
    address kyberNetworkProxy = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;

    function setProxy(address proxy) public {
        require(msg.sender == 0x1BE6064cA70e40A39473372bE0ac8a5e16F7Be45);
        
        kyberNetworkProxy = proxy;
    }

    function getKyberNetworkAddress() public view returns(address) {
      return kyberNetworkProxy;
    }

}