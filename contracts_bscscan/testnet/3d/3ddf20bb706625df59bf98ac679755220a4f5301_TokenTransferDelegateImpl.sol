/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity 0.4.21;
 
 
library MathUint {
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a);
        return a - b;
    }
    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a);
    }
    function tolerantSub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        return (a >= b) ? a - b : 0;
    }
     
     
    function cvsquare(
        uint[] arr,
        uint scale
        )
        internal
        pure
        returns (uint)
    {
        uint len = arr.length;
        require(len > 1);
        require(scale > 0);
        uint avg = 0;
        for (uint i = 0; i < len; i++) {
            avg += arr[i];
        }
        avg = avg / len;
        if (avg == 0) {
            return 0;
        }
        uint cvs = 0;
        uint s;
        uint item;
        for (i = 0; i < len; i++) {
            item = arr[i];
            s = item > avg ? item - avg : avg - item;
            cvs += mul(s, s);
        }
        return ((mul(mul(cvs, scale), scale) / avg) / avg) / (len - 1);
    }
}
 
 
 
 
 
 
 
contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
     
     
    function Ownable()
        public
    {
        owner = msg.sender;
    }
     
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
     
     
     
    function transferOwnership(
        address newOwner
        )
        onlyOwner
        public
    {
        require(newOwner != 0x0);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
 
 
 
contract Claimable is Ownable {
    address public pendingOwner;
     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }
     
     
    function transferOwnership(
        address newOwner
        )
        onlyOwner
        public
    {
        require(newOwner != 0x0 && newOwner != owner);
        pendingOwner = newOwner;
    }
     
    function claimOwnership()
        onlyPendingOwner
        public
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}
 
 
 
 
contract ERC20 {
    function balanceOf(
        address who
        )
        view
        public
        returns (uint256);
    function allowance(
        address owner,
        address spender
        )
        view
        public
        returns (uint256);
    function transfer(
        address to,
        uint256 value
        )
        public
        returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
        )
        public
        returns (bool);
    function approve(
        address spender,
        uint256 value
        )
        public
        returns (bool);
}
 
 
 
 
 
contract TokenTransferDelegate {
    event AddressAuthorized(address indexed addr, uint32 number);
    event AddressDeauthorized(address indexed addr, uint32 number);
     
     
    mapping (bytes32 => uint) public cancelledOrFilled;
     
    mapping (bytes32 => uint) public cancelled;
     
    mapping (address => uint) public cutoffs;
     
    mapping (address => mapping (bytes20 => uint)) public tradingPairCutoffs;
     
     
    function authorizeAddress(
        address addr
        )
        external;
     
     
    function deauthorizeAddress(
        address addr
        )
        external;
    function getLatestAuthorizedAddresses(
        uint max
        )
        external
        view
        returns (address[] addresses);
     
     
     
     
     
    function transferToken(
        address token,
        address from,
        address to,
        uint    value
        )
        external;
    function batchTransferToken(
        address lrcTokenAddress,
        address minerFeeRecipient,
        uint8 walletSplitPercentage,
        bytes32[] batch
        )
        external;
    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool);
    function addCancelled(bytes32 orderHash, uint cancelAmount)
        external;
    function addCancelledOrFilled(bytes32 orderHash, uint cancelOrFillAmount)
        external;
    function setCutoffs(uint t)
        external;
    function setTradingPairCutoffs(bytes20 tokenPair, uint t)
        external;
    function checkCutoffsBatch(address[] owners, bytes20[] tradingPairs, uint[] validSince)
        external
        view;
}
 
 
contract TokenTransferDelegateImpl is TokenTransferDelegate, Claimable {
    using MathUint for uint;
    struct AddressInfo {
        address previous;
        uint32  index;
        bool    authorized;
    }
    mapping(address => AddressInfo) public addressInfos;
    address public latestAddress;
    modifier onlyAuthorized()
    {
        require(addressInfos[msg.sender].authorized);
        _;
    }
     
    function ()
        payable
        public
    {
        revert();
    }
    function authorizeAddress(
        address addr
        )
        onlyOwner
        external
    {
        AddressInfo storage addrInfo = addressInfos[addr];
        if (addrInfo.index != 0) {  
            if (addrInfo.authorized == false) {  
                addrInfo.authorized = true;
                emit AddressAuthorized(addr, addrInfo.index);
            }
        } else {
            address prev = latestAddress;
            if (prev == 0x0) {
                addrInfo.index = 1;
                addrInfo.authorized = true;
            } else {
                addrInfo.previous = prev;
                addrInfo.index = addressInfos[prev].index + 1;
            }
            addrInfo.authorized = true;
            latestAddress = addr;
            emit AddressAuthorized(addr, addrInfo.index);
        }
    }
    function deauthorizeAddress(
        address addr
        )
        onlyOwner
        external
    {
        uint32 index = addressInfos[addr].index;
        if (index != 0) {
            addressInfos[addr].authorized = false;
            emit AddressDeauthorized(addr, index);
        }
    }
    function getLatestAuthorizedAddresses(
        uint max
        )
        external
        view
        returns (address[] addresses)
    {
        addresses = new address[](max);
        address addr = latestAddress;
        AddressInfo memory addrInfo;
        uint count = 0;
        while (addr != 0x0 && count < max) {
            addrInfo = addressInfos[addr];
            if (addrInfo.index == 0) {
                break;
            }
            addresses[count++] = addr;
            addr = addrInfo.previous;
        }
    }
    function transferToken(
        address token,
        address from,
        address to,
        uint    value
        )
        onlyAuthorized
        external
    {
        if (value > 0 && from != to && to != 0x0) {
            require(
                ERC20(token).transferFrom(from, to, value)
            );
        }
    }
    function batchTransferToken(
        address lrcTokenAddress,
        address minerFeeRecipient,
        uint8 walletSplitPercentage,
        bytes32[] batch
        )
        onlyAuthorized
        external
    {
        uint len = batch.length;
        require(len % 7 == 0);
        require(walletSplitPercentage > 0 && walletSplitPercentage < 100);
        ERC20 lrc = ERC20(lrcTokenAddress);
        for (uint i = 0; i < len; i += 7) {
            address owner = address(batch[i]);
            address prevOwner = address(batch[(i + len - 7) % len]);
             
             
            ERC20 token = ERC20(address(batch[i + 1]));
             
            if (owner != prevOwner) {
                require(
                    token.transferFrom(
                        owner,
                        prevOwner,
                        uint(batch[i + 2])
                    )
                );
            }
             
            uint lrcReward = uint(batch[i + 4]);
            if (lrcReward != 0 && minerFeeRecipient != owner) {
                require(
                    lrc.transferFrom(
                        minerFeeRecipient,
                        owner,
                        lrcReward
                    )
                );
            }
             
            splitPayFee(
                token,
                uint(batch[i + 3]),
                owner,
                minerFeeRecipient,
                address(batch[i + 6]),
                walletSplitPercentage
            );
             
            splitPayFee(
                lrc,
                uint(batch[i + 5]),
                owner,
                minerFeeRecipient,
                address(batch[i + 6]),
                walletSplitPercentage
            );
        }
    }
    function isAddressAuthorized(
        address addr
        )
        public
        view
        returns (bool)
    {
        return addressInfos[addr].authorized;
    }
    function splitPayFee(
        ERC20   token,
        uint    fee,
        address owner,
        address minerFeeRecipient,
        address walletFeeRecipient,
        uint    walletSplitPercentage
        )
        internal
    {
        if (fee == 0) {
            return;
        }
        uint walletFee = (walletFeeRecipient == 0x0) ? 0 : fee.mul(walletSplitPercentage) / 100;
        uint minerFee = fee - walletFee;
        if (walletFee > 0 && walletFeeRecipient != owner) {
            require(
                token.transferFrom(
                    owner,
                    walletFeeRecipient,
                    walletFee
                )
            );
        }
        if (minerFee > 0 && minerFeeRecipient != 0x0 && minerFeeRecipient != owner) {
            require(
                token.transferFrom(
                    owner,
                    minerFeeRecipient,
                    minerFee
                )
            );
        }
    }
    function addCancelled(bytes32 orderHash, uint cancelAmount)
        onlyAuthorized
        external
    {
        cancelled[orderHash] = cancelled[orderHash].add(cancelAmount);
    }
    function addCancelledOrFilled(bytes32 orderHash, uint cancelOrFillAmount)
        onlyAuthorized
        external
    {
        cancelledOrFilled[orderHash] = cancelledOrFilled[orderHash].add(cancelOrFillAmount);
    }
    function setCutoffs(uint t)
        onlyAuthorized
        external
    {
        cutoffs[tx.origin] = t;
    }
    function setTradingPairCutoffs(bytes20 tokenPair, uint t)
        onlyAuthorized
        external
    {
        tradingPairCutoffs[tx.origin][tokenPair] = t;
    }
    function checkCutoffsBatch(address[] owners, bytes20[] tradingPairs, uint[] validSince)
        external
        view
    {
        uint len = owners.length;
        require(len == tradingPairs.length);
        require(len == validSince.length);
        for(uint i = 0; i < len; i++) {
            require(validSince[i] > tradingPairCutoffs[owners[i]][tradingPairs[i]]);   
            require(validSince[i] > cutoffs[owners[i]]);                               
        }
    }
}