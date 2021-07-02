/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {

    function setPaymentDate(uint256 _asset) external;
    function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, string memory coin);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address _owner) external view returns (uint256);
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

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract PolkaProfitContract is Ownable {
    
    event Payment(address indexed to, uint256 amount, uint8 network, uint256 gasFee);
    
    bool public paused;

    struct Claim {
        address account;
        uint8 dNetwork;  // 1= Ethereum   2= BSC
        uint256 assetId;
        uint256 amount;
        uint256 date;
    }
    
    Claim[] public payments;
    
    mapping (address => bool) public blackListed;
    mapping (uint256 => uint256) public weeklyByType;
    address public nftAddress = 0xB20217bf3d89667Fa15907971866acD6CcD570C8;
    address public tokenAddress = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
    address payable public walletAddress;
    uint256 public gasFee = 1000000000000000;
    mapping (uint256 => uint256) public bankWithdraws;
    uint256 public bankEarnings;
    address bridgeContract;
    

    uint256 wUnit = 1 weeks;
    
    constructor() {
        weeklyByType[20] = 18 ether;
        weeklyByType[22] = 4 ether;
        weeklyByType[23] = 3 ether;
        weeklyByType[25] = 1041 ether;
        weeklyByType[26] = 44 ether;
        weeklyByType[29] = 3125 ether;
        weeklyByType[30] = 29 ether;
        weeklyByType[31] = 5 ether;
        weeklyByType[32] = 20 ether;
        weeklyByType[34] = 10 ether;
        weeklyByType[36] = 70 ether;
        weeklyByType[37] = 105 ether;
        weeklyByType[38] = 150 ether;
        weeklyByType[39] = 600 ether;
        weeklyByType[40] = 20 ether;
        
        walletAddress = payable(0xAD334543437EF71642Ee59285bAf2F4DAcBA613F);
        bridgeContract = 0x0A0b052D93EaA7C67F498fb3F8D9f4f56456BA51;
    }
    
    function profitsPayment(uint256 _assetId) public returns (bool success) {
        require(paused == false, "Contract is paused");
        IERC721 nft = IERC721(nftAddress);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetOwner == msg.sender, "Only asset owner can claim profits");
        require(blackListed[assetOwner] == false, "This address cannot claim profits");
        (uint256 totalPayment, ) = calcProfit(_assetId);
        require (totalPayment > 0, "You need to wait at least 1 week to claim");
        nft.setPaymentDate(_assetId);
        IERC20Token token = IERC20Token(tokenAddress);
        require(token.transferFrom(walletAddress, assetOwner, totalPayment), "ERC20 transfer fail");
        Claim memory thisclaim = Claim(msg.sender, 1, _assetId, totalPayment, block.timestamp);
        payments.push(thisclaim);
        emit Payment(msg.sender, totalPayment, 1, 0);
        return true;
    }
    
    function profitsPaymentBSC(uint256 _assetId) public payable returns (bool success) {
        require(paused == false, "Contract is paused");
        require(msg.value >= gasFee, "Gas fee too low");
        IERC721 nft = IERC721(nftAddress);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetOwner == msg.sender, "Only asset owner can claim profits");
        require(blackListed[assetOwner] == false, "This address cannot claim profits");
        (uint256 totalPayment, ) = calcProfit(_assetId);
        require (totalPayment > 0, "You need to wait at least 1 week to claim");
        nft.setPaymentDate(_assetId);
        Address.sendValue(walletAddress, msg.value);
        Claim memory thisclaim = Claim(msg.sender, 2, _assetId, totalPayment, block.timestamp);
        payments.push(thisclaim);
        emit Payment(msg.sender, totalPayment, 2, msg.value);
        return true;
    }
    
    function calcProfit(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,, uint32 lastTransfer, uint32 lastPayment,, ) = nft.getTokenDetails(_assetId);
        uint256 cTime = block.timestamp - lastTransfer;
        uint256 dTime = 0;
        if (lastTransfer < lastPayment) {
            dTime = lastPayment - lastTransfer;
        }
        if ((cTime) < wUnit) { 
            return (0, lastTransfer);
        } else {
             uint256 weekCount;  
            if (dTime == 0) {
                weekCount = ((cTime)/(wUnit));
            } else {
                weekCount = ((cTime)/(wUnit)) - (dTime)/(wUnit);
            }
            if (weekCount < 1) {
                return (0, lastPayment);
            } else {
                uint256 totalPayment;
                totalPayment = ((weekCount * weeklyByType[assetType]));
                return (totalPayment, lastPayment);  
                
            }
        }
    }
    
    function calcTotalEarnings(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,, uint32 lastTransfer,,, ) = nft.getTokenDetails(_assetId);
        uint256 timeFrame = block.timestamp - lastTransfer;
        if (timeFrame < wUnit) {  
            return (0, lastTransfer);
        } else {
            uint256 weekCount = timeFrame/(wUnit); 
            uint256 totalPayment;
            totalPayment = ((weekCount * weeklyByType[assetType]));
            return (totalPayment, lastTransfer);    
        }

    }
    

    function pauseContract(bool _paused) public onlyOwner {
        paused = _paused;
    }
    
    function blackList(address _wallet, bool _blacklist) public onlyOwner {
        blackListed[_wallet] = _blacklist;
    }

    function paymentCount() public view returns (uint256 _paymentCount) {
        return payments.length;
    }
    
    function paymentDetail(uint256 _paymentIndex) public view returns (address _to, uint8 _network, uint256 assetId, uint256 _amount, uint256 _date) {
        Claim memory thisPayment = payments[_paymentIndex];
        return (thisPayment.account, thisPayment.dNetwork, thisPayment.assetId, thisPayment.amount, thisPayment.date);
    }
    
    function addType(uint256 _aType, uint256 _weekly) public onlyOwner {
        weeklyByType[_aType] = _weekly;
    }
    
    function setGasFee(uint256 _gasFee) public onlyOwner {
        gasFee = _gasFee;
    }
    
    function setWalletAddress(address _wallet) public onlyOwner {
        walletAddress = payable(_wallet);
    }
    
    function setBridgeContract(address _contract) public onlyOwner {
        bridgeContract = _contract;
    }
    
    function addBankEarnings(uint256 _amount) public {
        require(msg.sender == bridgeContract, "Not Allowed");
        bankEarnings += _amount;
    }
    
    function claimBankEarnings(uint256 _assetId) public {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,,,,, ) = nft.getTokenDetails(_assetId);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetType == 33, "Invalid asset");
        uint256 toPay = bankEarnings - bankWithdraws[_assetId];
        if (toPay > 0) {
            bankWithdraws[_assetId] = bankEarnings;
            IERC20Token token = IERC20Token(tokenAddress);
            require(token.transferFrom(walletAddress, assetOwner, toPay), "ERC20 transfer fail");
            emit Payment(assetOwner, toPay, 2, 0);
        }
    }
    
    function claimBankEarningsBSC(uint256 _assetId) public payable {
        IERC721 nft = IERC721(nftAddress);
        (uint32 assetType,,,,, ) = nft.getTokenDetails(_assetId);
        address assetOwner = nft.ownerOf(_assetId);
        require(assetType == 33, "Invalid asset");
        uint256 toPay = bankEarnings - bankWithdraws[_assetId];
        if (toPay > 0) {
            bankWithdraws[_assetId] = bankEarnings;
            Claim memory thisclaim = Claim(assetOwner, 2, _assetId, toPay, block.timestamp);
            payments.push(thisclaim);
            emit Payment(assetOwner, toPay, 2, msg.value);
        }

    }
    


    
}