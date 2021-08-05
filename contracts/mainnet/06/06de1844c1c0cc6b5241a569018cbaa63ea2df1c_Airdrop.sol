pragma solidity 0.6.12;


import "SafeERC20.sol";
import "SafeMath.sol";

contract Farming {
    function  getLPToken(uint256 _pid) public view returns(address){}
    function  getLPBlance(uint256 _pid, address _address) public view returns(uint256){}
}

contract Airdrop {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct User {
        uint256 quota;
        uint256 claimed;
    }

    // The ERC20 TOKEN!
    IERC20 public token;
    uint256 public supply;
    address public signer;
    Farming public farmingPool;
    uint256 poolID;

    mapping (address => User) public users;

    event Claimed(address indexed user,  uint256 amount);


    constructor(
        IERC20 _token,
        uint256 _supply,
        address _signer,
        address _farmingPool,
        uint256 _poolID
    ) public {
        token = _token;
        supply = _supply;
        signer = _signer;
        farmingPool = Farming(_farmingPool);
        poolID = _poolID;
    }


    function totalMinted() public view returns (uint256){
        return token.totalSupply().div(20);
    }

    function totalClaimed() public view returns (uint256){
        return totalMinted().sub(token.balanceOf(address(this)));
    }

    function balanceOf(address _address) public view returns(uint256, uint256, uint256, uint256){
          uint256 factor = getReleaseFactor(_address);
          uint256 pending = 0;
          if(totalMinted().mul(users[_address].quota).div(supply).mul(factor) >=users[_address].claimed){
              pending = totalMinted().mul(users[_address].quota).div(supply).mul(factor).sub(users[_address].claimed);
          }

          if(users[_address].claimed.add(pending)>users[_address].quota){
              pending = users[_address].quota.sub(users[_address].claimed);
          }
          uint256 quota = users[_address].quota;
          uint256 claimed = users[_address].claimed;

          return (quota, claimed, pending, factor);
    }

    function getReleaseFactor(address _address) public view returns(uint256){
        uint256 factor = 1;
        uint256 lpBalance = farmingPool.getLPBlance(poolID,_address);
        if(lpBalance>0){
            IERC20 uni_contract = IERC20(farmingPool.getLPToken(poolID));
            uint256 equalTotal = lpBalance.mul(token.balanceOf(farmingPool.getLPToken(poolID))).div(uni_contract.totalSupply());
            if(equalTotal>=1000*1e18){
                factor = 4;
            }
        }

        return factor;
    }

    function claim(string calldata message, bytes calldata signature) public {
        //verify signer
        bytes32 messageHash = getMessageHash(message);
        if(recoverSigner(messageHash,signature) == signer ){
            //verify sender
            bytes calldata  _msg = bytes(message);
            address decodedAddress = parseAddr(substring(message, 0, 42));
            uint256 decodedQuota = stringToUint256(substring(message, 43, _msg.length)).mul(1e18);
            if(decodedAddress == msg.sender){
                if(users[msg.sender].quota >0){
                    //transfer
                    sendToken(msg.sender);
                }else{
                    users[msg.sender] = User({
                          quota: decodedQuota,
                          claimed: 0
                    });
                    if(users[msg.sender].quota >0){
                        //transfer
                        sendToken(msg.sender);
                    }else{
                          revert("insufficient quota");
                    }
                }

            }else{
                revert("invalid sender");
            }
        }else{
            revert("invalid sign");
        }
    }


   function recoverSigner(bytes32  _ethSignedMessageHash, bytes calldata _signature)
       public pure returns (address)
   {
       (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
       return ecrecover(_ethSignedMessageHash, v, r, s);
   }

   function splitSignature(bytes memory sig)
       public pure returns (bytes32 r, bytes32 s, uint8 v)
   {
       require(sig.length == 65, "invalid signature length");
       assembly {
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
       return (r, s, v);
   }

   function getMessageHash(string memory _message)
        public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n",uintToStr(bytes(_message).length), _message));
    }

   function uintToStr(uint _i) internal pure returns (string memory) {
        uint number = _i;
        if (number == 0) {
            return "0";
        }
        uint j = number;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (number != 0) {
            bstr[k--] = byte(uint8(48 + number % 10));
            number /= 10;
        }
        return string(bstr);
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
            bytes memory tmp = bytes(_a);
            uint160 iaddr = 0;
            uint160 b1;
            uint160 b2;
            for (uint i = 2; i < 2 + 2 * 20; i += 2) {
                iaddr *= 256;
                b1 = uint160(uint8(tmp[i]));
                b2 = uint160(uint8(tmp[i + 1]));
                if ((b1 >= 97) && (b1 <= 102)) {
                    b1 -= 87;
                } else if ((b1 >= 65) && (b1 <= 70)) {
                    b1 -= 55;
                } else if ((b1 >= 48) && (b1 <= 57)) {
                    b1 -= 48;
                }
                if ((b2 >= 97) && (b2 <= 102)) {
                    b2 -= 87;
                } else if ((b2 >= 65) && (b2 <= 70)) {
                    b2 -= 55;
                } else if ((b2 >= 48) && (b2 <= 57)) {
                    b2 -= 48;
                }
                iaddr += (b1 * 16 + b2);
            }
            return address(iaddr);
        }
     function stringToUint256(string memory s) public view returns (uint256) {
        bytes memory b = bytes(s);
        uint256 i;
        uint result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }
    function substring(string calldata str, uint startIndex, uint endIndex) public view returns (string memory) {
        bytes calldata  strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
    function sendToken(address  receiver)  internal {
        uint256 factor = getReleaseFactor(receiver);
        uint256 available = 0;
        if(totalMinted().mul(users[receiver].quota).div(supply).mul(factor)>=users[receiver].claimed){
            available = totalMinted().mul(users[receiver].quota).div(supply).mul(factor).sub(users[receiver].claimed);
        }

        if(users[receiver].claimed.add(available)>users[receiver].quota){
            available = users[receiver].quota.sub(users[receiver].claimed);
        }
        if(available  >= token.balanceOf(address(this))){
            available = token.balanceOf(address(this));
        }
        token.transfer(receiver, available);
        users[receiver].claimed = users[receiver].claimed.add(available);
        emit Claimed(receiver, available);
    }
}
