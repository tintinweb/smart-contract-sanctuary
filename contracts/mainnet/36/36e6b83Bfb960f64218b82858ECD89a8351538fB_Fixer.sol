interface Ilsw {
     function setDELTAToken(address deltaToken, bool delegateCall) external;
}

contract Fixer {

    address public owner;
    address public pendingLSWOwner;
    Ilsw constant LSW = Ilsw(0xdaFCE5670d3F67da9A3A44FE6bc36992e5E2beaB);
    address public addressToFix;
    address public fixer;

    constructor () public {
        owner = msg.sender;
        pendingLSWOwner = address(this);  //  we get the LSW first can swithc back out of it with switchLSWOwner
    }

    function setOwnerOfFixerContract(address _newOwner) public onlyOwner() {
        owner = _newOwner;
    }

    function setFixerDelegate(address _newFixer) public onlyOwner() {
        fixer = _newFixer;
    }

    function switchLSWOwner(address _newOwner) public onlyOwner() {
        pendingLSWOwner = _newOwner;
        callDelegate();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fixAddress(address _addressToFix)  public  {
        addressToFix = _addressToFix;
        callDelegate();
        addressToFix = address(0);
    }

    function callDelegate() internal {
        LSW.setDELTAToken(fixer, true);
    }



}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}