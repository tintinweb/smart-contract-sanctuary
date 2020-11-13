pragma solidity ^0.6.7;

interface IERC1155 {
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 value, bytes calldata _data) external;
}

interface IERC20 {
    function transfer(address _dst, uint256 _amount) external returns (bool);
}

contract SeenClaimer {

    IERC20   public seen;
    IERC1155 public tokens;
    IERC1155        secret;
    uint256  public amount = 710000000000000000000; 

    uint256[] public batches = [1,2,3,4,5];

    constructor() public {
        tokens = IERC1155(0xb9341CCa0A5F04b804F7b3a996A74726923359a8);
        seen = IERC20(0xCa3FE04C7Ee111F0bbb02C328c699226aCf9Fd33);
        secret = IERC1155(0x13bAb10a88fc5F6c77b87878d71c9F1707D2688A);
    }

    function claim(address _user) public {
        address[] memory user = new address[](5);
        user[0] = _user;
        user[1] = _user;
        user[2] = _user;
        user[3] = _user;
        user[4] = _user;
        uint256[] memory balances = tokens.balanceOfBatch(user, batches);
        uint256 sum = 0;
        for (uint i = 0; i < balances.length; i++){
            sum += balances[i];
        }
        require(sum > 0, "no tokens");
        tokens.safeBatchTransferFrom(_user, address(this), batches, balances, new bytes(0x0));
        secret.safeTransferFrom(address(this), _user, 1, 1, new bytes(0x0));
        seen.transfer(_user, sum * amount);
    }
    
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}