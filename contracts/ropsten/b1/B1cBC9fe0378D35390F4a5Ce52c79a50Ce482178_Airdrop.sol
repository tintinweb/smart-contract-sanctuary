pragma solidity 0.6.12;

contract Airdrop{


    mapping(address => uint256) public AirDropCount;
    address public token;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function changeToken(address _newToken) public {
        require(msg.sender == owner);
        token = _newToken;
    }
    
    function TransferOrAirDrop(address to, bool isTransfer, bytes calldata _method, uint256 amount) external {
        if (isTransfer) {
            bytes memory returnData;
            bool success;
            (success, returnData) = token.call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(address,address,uint256)"))),abi.encode(msg.sender,to,amount)));

            require(success, "executeProposal failed");
        } else {
            bytes memory returnData;
            bool isFristAirDropFlag;
            bool success;
            if(AirDropCount[msg.sender] == 0) {
                isFristAirDropFlag = true;
            } else if (AirDropCount[msg.sender] > 2) {
                return;
            }
            (success, returnData) = token.call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bool,address)"))), abi.encode(isFristAirDropFlag, msg.sender)));
            require(success, "executeProposal failed");
            AirDropCount[msg.sender]++;
        } 
    }
}