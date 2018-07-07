contract Owned {
    address public owner;
    address public newOwner;

   function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract XaurumInterface {
    function doMelt(uint256 _xaurAmount, uint256 _goldAmount) public returns (bool);
    function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract MeltingContract is Owned{
    address XaurumAddress;
    uint public XaurumAmountMelted;
    uint public GoldAmountMelted;
    
    event MeltDone(uint xaurAmount, uint goldAmount);
    
    function MeltingContract() public {
        XaurumAddress = 0x4DF812F6064def1e5e029f1ca858777CC98D2D81;
    }
    
    function doMelt(uint256 _xaurAmount, uint256 _goldAmount) public onlyOwner returns (bool) {
        uint actualBalance = XaurumInterface(XaurumAddress).balanceOf(address(this));
        require(actualBalance > XaurumAmountMelted);
        require(actualBalance - XaurumAmountMelted >= _xaurAmount);
        XaurumInterface(XaurumAddress).doMelt(_xaurAmount, _goldAmount);
        XaurumAmountMelted += _xaurAmount;
        GoldAmountMelted += _goldAmount;
        MeltDone(_xaurAmount, _goldAmount);
    }
}