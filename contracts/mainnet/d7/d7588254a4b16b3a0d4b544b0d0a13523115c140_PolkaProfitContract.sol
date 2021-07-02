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
    function getTokenDetails(uint256 index) external view returns (uint128 lastvalue, uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment);
    function polkaCitizens() external view returns(uint256 _citizens);
    function assetsByType(uint256 _assetType) external view returns (uint64 maxAmount, uint64 mintedAmount, uint128 baseValue);
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

    struct paymentByType {
        uint256 weeklyPayment;
        uint256 variantFactor; 
        uint256 basePriceFactor;
    }
    
    struct Claim {
        address account;
        uint8 dNetwork;  // 1= Ethereum   2= BSC
        uint256 assetId;
        uint256 amount;
        uint256 date;
    }
    
    Claim[] public payments;
    
    mapping (address => bool) public blackListed;
    mapping (uint256 => paymentByType) public paymentAmount;
    address public nftAddress = 0x57E9a39aE8eC404C08f88740A9e6E306f50c937f;
    address public tokenAddress = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
    address payable public walletAddress;
    uint256 public gasFee = 1000000000000000;
    

    uint256 wUnit = 1 weeks;
    
    constructor() {
        fillPayments(1,    60000000000000000000, 10, 15000000000000);
        fillPayments(2,   135000000000000000000, 10, 30000000000000);
        fillPayments(3,   375000000000000000000, 10, 75000000000000);
        fillPayments(4,   550000000000000000000, 10, 100000000000000);
        fillPayments(5,   937500000000000000000, 10, 150000000000000);
        fillPayments(6,  8250000000000000000000, 10, 750000000000000);
        fillPayments(7,  6500000000000000000000, 10, 655000000000000);
        fillPayments(8,  3000000000000000000000, 20, 400000000000000);
        fillPayments(9, 10800000000000000000000, 50, 900000000000000);
        fillPayments(10, 5225000000000000000000, 30, 550000000000000);
        fillPayments(11,13125000000000000000000, 20, 1050000000000000);
        fillPayments(12, 4500000000000000000000, 10, 500000000000000);
        fillPayments(13, 1500000000000000000000, 10, 225000000000000);
        fillPayments(14, 2100000000000000000000, 15, 300000000000000);
        fillPayments(15, 3750000000000000000000, 10, 450000000000000);
        
        walletAddress = payable(0xAD334543437EF71642Ee59285bAf2F4DAcBA613F);

    }
    
    function fillPayments(uint256 _assetId, uint256 _weeklyPayment, uint256 _variantFactor, uint256 _basePriceFactor) private {
        paymentAmount[_assetId].weeklyPayment = _weeklyPayment;
        paymentAmount[_assetId].variantFactor = _variantFactor;
        paymentAmount[_assetId].basePriceFactor = _basePriceFactor;
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
        Claim memory thisclaim = Claim(msg.sender, 1,  _assetId, totalPayment, block.timestamp);
        payments.push(thisclaim);
        emit Payment(msg.sender, totalPayment, 1, 0);
        return true;
    }
    
    function profitsPaymentBSC(uint256 _assetId) public payable  returns (bool success) {
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
        ( , uint32 assetType,, uint32 lastTransfer, uint32 lastPayment ) = nft.getTokenDetails(_assetId);
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
                uint256 daysCount = weekCount * 7; //  
                uint256 variantCount;
                if (assetType == 8 || assetType == 15) {
                    variantCount = countTaxis();
                } else {
                    variantCount = nft.polkaCitizens();
                }
                uint256 totalPayment;
                paymentByType memory thisPayment = paymentAmount[uint256(assetType)];
                uint256 dailyProfit = ((thisPayment.basePriceFactor*(variantCount*thisPayment.variantFactor))/30)*daysCount;
                totalPayment = ((weekCount * thisPayment.weeklyPayment) + dailyProfit);
                return (totalPayment, lastPayment);  
                
            }
        }
    }
    
    function calcTotalEarnings(uint256 _assetId) public view returns (uint256 _profit, uint256 _lastPayment) {
        IERC721 nft = IERC721(nftAddress);
        ( , uint32 assetType,, uint32 lastTransfer, ) = nft.getTokenDetails(_assetId);
        uint256 timeFrame = block.timestamp - lastTransfer;
        if (timeFrame < wUnit) {  
            return (0, lastTransfer);
        } else {
            uint256 weekCount = timeFrame/(wUnit); 
            uint256 daysCount = weekCount * 7;  
            uint256 variantCount;
            if (assetType == 8 || assetType == 15) {
                variantCount = countTaxis();
            } else {
                variantCount = nft.polkaCitizens();
            }
            uint256 totalPayment;
            paymentByType memory thisPayment = paymentAmount[uint256(assetType)];
            uint256 dailyProfit = ((thisPayment.basePriceFactor*(variantCount*thisPayment.variantFactor))/30)*daysCount;
            totalPayment = ((weekCount * thisPayment.weeklyPayment) + dailyProfit);
            return (totalPayment, lastTransfer);    
        }

    }
    

    function countTaxis() private view returns (uint256 taxis) {
        uint256 taxiCount = 0;
        uint64 assetMinted;
        IERC721 nft = IERC721(nftAddress);
        (, assetMinted,) = nft.assetsByType(1);
        taxiCount += uint256(assetMinted);
        (, assetMinted,) = nft.assetsByType(2);
        taxiCount += uint256(assetMinted);
        (, assetMinted,) = nft.assetsByType(3);
        taxiCount += uint256(assetMinted);
        (, assetMinted,) = nft.assetsByType(4);
        taxiCount += assetMinted;
        (, assetMinted,) = nft.assetsByType(5);
        taxiCount += uint256(assetMinted);
        return taxiCount;
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
    
    function setGasFee(uint256 _gasFee) public onlyOwner {
        gasFee = _gasFee;
    }
    
    function setWalletAddress(address _wallet) public onlyOwner {
        walletAddress = payable(_wallet);
    }
    
    
}