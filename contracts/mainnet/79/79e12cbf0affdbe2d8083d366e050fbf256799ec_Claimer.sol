pragma solidity ^0.6.7;

interface IERC1155 {
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
}

contract Claimer {

    IERC1155 public tokens;
    address  public deployer;
    uint256  public end;

    uint256[] public batches = [1,2,3,4,5];

    constructor() public {
        tokens = IERC1155(0xb9341CCa0A5F04b804F7b3a996A74726923359a8);
        deployer = msg.sender;
        end = block.timestamp + 2 weeks;
    }

    function claim(address payable _user) public {
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
        tokens.safeBatchTransferFrom(_user, address(this), batches, balances, new bytes(0x0));
        _user.transfer(sum * 1 ether);
    }

    function returnEth(address payable _who) external {
        require(msg.sender == deployer, "!deployer");
        require(block.timestamp > end, "not yet");
        _who.transfer(address(this).balance);
    }
    
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external pure returns(bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}