/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
    function balanceOf(
        address owner)
        external view 
        returns (uint256 balance);
    function updatePass(address user, uint amount) external;

}


library Address {
   
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeIERC721{
    using Address for address;
    function _SafeIERC721(IERC721 token,address user,uint amount) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.updatePass.selector, user, amount));
    }
    function callOptionalReturn(IERC721 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "Safe: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC: ERC operation did not succeed");
        }
    }
}

contract UpdateProxy {
    using SafeIERC721 for IERC721;

    IERC721 public Token;
    constructor(address _token){
        Token = IERC721(_token);
    }

    function updater(address user, uint amount) internal{
        Token._SafeIERC721(user, amount);
    }
}
/*

///                                ___                                
//                                (   )      .-.                      
//    .---.   ___  ___    .--.     | |_     ( __)   .--.    ___ .-.   
/    / .-, \ (   )(   )  /    \   (   __)   (''")  /    \  (   )   \  
/   (__) ; |  | |  | |  |  .-. ;   | |       | |  |  .-. ;  |  .-. .  
///   .'`  |  | |  | |  |  |(___)  | | ___   | |  | |  | |  | |  | |  
/    / .'| |  | |  | |  |  |       | |(   )  | |  | |  | |  | |  | |  
/   | /  | |  | |  | |  |  | ___   | | | |   | |  | |  | |  | |  | |  
/   ; |  ; |  | |  ; '  |  '(   )  | ' | |   | |  | '  | |  | |  | |  
/   ' `-'  |  ' `-'  /  '  `-' |   ' `-' ;   | |  '  `-' /  | |  | |  
/   `.__.'_.   '.__.'    `.__,'     `.__.   (___)  `.__.'  (___)(___) 

*/
contract EnglishAuction is UpdateProxy{
    using SafeIERC721 for IERC721;
    // 
    event NewAuctionCreated(uint endsAt);
    event Bid(address indexed sender,uint bidNumber ,uint amount);
    event Winner(address indexed bidder);
    event End(address indexed winner, uint amount);
    event Lost(address indexed Loser);
    // State Variables 
    address payable public owner;
    IERC721 public NftMintPass;
    IERC721 public AuctionTicket;
    uint public nftId;
    uint public AuctionNo = 0;
    
    // Struct 
    struct _auction{
        uint endAt;
        bool started;
        bool ended;
        uint highestBid;
        uint lowestbid;
        uint bidders;
    }
    struct bids{
        uint[] _bids;
    }

    // Mappings 
    mapping(uint => _auction) public auction;
    mapping(address => uint) internal _pass;
    mapping(address => mapping(uint => bids)) internal _noOfBidsPerPerson;
    mapping(address => mapping(uint => uint)) internal _bidPerPerson;
    
    
    // modifier 
    modifier onlyOwner(){
        require(msg.sender == owner,"Only Owner can run this function");
        _;
    }


    // constructor 
    constructor(
        address _NftMintPass,
        address _AuctionTicket,
        address payable _owner
    ) UpdateProxy(_NftMintPass) {
        NftMintPass = IERC721(_NftMintPass);

        AuctionTicket = IERC721(_AuctionTicket);
        owner = _owner;
    }


    //  Functions 

    receive() external payable {}
    fallback() external payable {}

    function createNewAuction(
        uint _endAt,
        uint _lowestbid) public onlyOwner returns(bool){
        AuctionNo++;
        _auction storage a = auction[AuctionNo];
        (a.endAt=(_endAt+block.timestamp),a.started=true,a.ended=false,
        a.highestBid=0,a.bidders=0,a.lowestbid=_lowestbid);
        emit NewAuctionCreated(_endAt);
        return true;
    }

    function checkAuction(uint _auctionNumber)public view returns(uint,bool,bool,uint,uint){
        _auction storage a = auction[_auctionNumber];
        return(a.endAt,a.started,a.ended,a.highestBid,a.lowestbid);
    }
    // complete Logic & tested 
    function bid() external payable {
        _auction storage a = auction[AuctionNo];
        require(a.started == true , "Auction is not started yet");
        require(block.timestamp < a.endAt, "Auction is already Ended!");
        require(msg.value > a.lowestbid, "value must be higher then lowest");
        require(AuctionTicket.balanceOf(msg.sender) >= 1, "You must have Token ");
        require(msg.value > a.highestBid,"please enter amount higher then Previous bid");
        a.lowestbid = msg.value;
        a.highestBid = msg.value;
        a.bidders +=1;
        bids storage b = _noOfBidsPerPerson[msg.sender][AuctionNo];
        b._bids.push(a.bidders);
        _bidPerPerson[msg.sender][a.bidders] = msg.value;
        (payable (address(this))).transfer(msg.value);
        emit Bid(msg.sender,a.bidders,msg.value);
    }

    function checkPass(address user) public view returns (uint) {
        return (_pass[user]);
    }
    
    // complete Logic & tested
    function checkBidsPerId() public view returns(uint[] memory){
        _auction storage a = auction[AuctionNo];
        bids storage b = _noOfBidsPerPerson[msg.sender][AuctionNo];
        uint[] memory number = new uint[](a.bidders);
        for(uint i =0; i < b._bids.length; i++ ){
            number[i] =  b._bids[i];
        }
            return (number);        
    }
    // complete Logic & tested 
    function withdraw(uint _auctionNo,uint bidId) external {
        _auction storage a = auction[_auctionNo];
        bids storage b = _noOfBidsPerPerson[msg.sender][AuctionNo];
        require(_bidPerPerson[msg.sender][bidId] != 0,"already claimed");
        for(uint i =0; i < b._bids.length; i++ ){
            if(b._bids[i] == bidId){
                if(bidId <= (a.bidders-50)){
                    (payable(msg.sender)).transfer(_bidPerPerson[msg.sender][bidId]);
                    _bidPerPerson[msg.sender][bidId] = 0;
                    emit Lost(msg.sender);
                }else if(bidId > (a.bidders-50)){
                    (owner).transfer(_bidPerPerson[msg.sender][bidId]);
                    passUpdate(msg.sender, 1);
                    _bidPerPerson[msg.sender][bidId] = 0;
                    emit Winner(msg.sender);
                }
            }
        }
    }

    function passUpdate(address user, uint amount) internal{
        super.updater(user, amount);
    }
}