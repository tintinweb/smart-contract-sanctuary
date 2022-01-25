contract Test {
    mapping(uint256 => address) public user;
    constructor(address[] memory _user) public {
        require((_user.length > 0),"bad length");
        for(uint256 i = 0 ; i < _user.length ; i++){
            user[i] = _user[i];
        }
    }
}