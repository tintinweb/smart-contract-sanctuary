contract test  {
    uint public a;
    bool public b;
    
    modifier onlyPendingOwner() {
    require(b,"must be pendingOwner");
    _;
  }

    function getA() internal view returns (uint256) {
        return a;
    }
    
}


contract test1 is test  {
    
    function action()  onlyPendingOwner() public view returns (uint256) {
    return getA();


}
}