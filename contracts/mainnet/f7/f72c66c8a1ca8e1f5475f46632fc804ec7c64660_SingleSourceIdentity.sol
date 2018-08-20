pragma solidity ^0.4.17;

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Authority {
    function isValidAuthority(address authorityAddress, uint blockNumber) public view returns (bool);
}

contract SafeMath {
    function safeSub(uint a, uint b) pure internal returns (uint) {
        sAssert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        sAssert(c>=a && c>=b);
        return c;
    }

    function sAssert(bool assertion) pure internal {
        if (!assertion) {
            revert();
        }
    }
}

contract SingleSourceIdentity is SafeMath {
    // Struct and enum
    struct KYC {
        bool verified;
        address verifiedBy;
        uint verifiedAt;
        uint verifiedAttributes;
    }

    // Instance variables
    uint public verificationFee;
    mapping(address => uint) public verificationFeeBalances;

    address public owner;
    address public authorityContractAddress;
    address public paymentContractAddress;
    mapping(address => KYC) public records;

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier onlyValidAuthority(address authorityAddress) {
        if (!isValidAuthority(authorityAddress)) {
            revert();
        }

        _;
    }

    modifier onlyAuthoritativeAuthority(address authorityAddress, address userAddress) {
        // Verifier verification
        KYC storage kycRecord = records[userAddress];
        if (kycRecord.verifiedBy != 0x0 && kycRecord.verifiedBy != authorityAddress) {
            if (isValidAuthority(kycRecord.verifiedBy)) {
                revert();
            }
        }

        _;
    }

    // Internal
    function isValidAuthority(address authorityAddress)
      private
      view
      returns (bool)
    {
        Authority authority = Authority(authorityContractAddress);
        return authority.isValidAuthority(authorityAddress, block.number);
    }

    function chargeVerificationFee(address userAddress, address authorityAddress)
      private
      returns (bool)
    {
        if (!ERC20(paymentContractAddress).transferFrom(userAddress, this, verificationFee)) {
            return false;
        }
        uint currentBalance = verificationFeeBalances[authorityAddress];
        verificationFeeBalances[authorityAddress] = safeAdd(currentBalance, verificationFee);
        return true;
    }

    // Init
    function SingleSourceIdentity()
      public
    {
        owner = msg.sender;
        verificationFee = 0 ether;
    }

    // Admin
    function setAuthorityContractAddress(address contractAddress)
      public
      onlyOwner()
    {
        authorityContractAddress = contractAddress;
    }

    function setPaymentContractAddress(address contractAddress)
      public
      onlyOwner()
    {
        paymentContractAddress = contractAddress;
    }

    function setFee(uint fee)
      public
      onlyOwner()
    {
        verificationFee = fee;
    }

    function changeOwner(address newOwner)
      public
      onlyOwner()
    {
        owner = newOwner;
    }

    function withdrawFee()
      public
      onlyValidAuthority(msg.sender)
    {
        require(paymentContractAddress != 0x0);

        uint balance = verificationFeeBalances[msg.sender];
        require(balance > 0);

        verificationFeeBalances[msg.sender] = 0;
        if (!ERC20(paymentContractAddress).transfer(msg.sender, balance)) {
            revert();
        }
    }

    // Functions
    function hasValidProfile(address userAddress)
      public
      view
      returns (bool)
    {
        KYC storage kyc = records[userAddress];
        if (kyc.verified) {
            Authority authority = Authority(authorityContractAddress);
            if (!authority.isValidAuthority(kyc.verifiedBy, kyc.verifiedAt)) {
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
    }

    function hasVerifiedAttributeIndex(address userAddress, uint attributeIndex)
      public
      view
      returns (bool)
    {
        if (!this.hasValidProfile(userAddress)) {
            return false;
        } else {
            KYC storage kyc = records[userAddress];
            uint attributeValue = 2 ** attributeIndex;
            return ((kyc.verifiedAttributes & attributeValue) == attributeValue);
        }
    }

    function hasVerifiedAttributeValue(address userAddress, uint attributeValue)
      public
      view
      returns (bool)
    {
        if (!this.hasValidProfile(userAddress)) {
            return false;
        } else {
            KYC storage kyc = records[userAddress];
            return ((kyc.verifiedAttributes & attributeValue) == attributeValue);
        }
    }


    function verifiedAttributes(address userAddress)
      public
      view
      returns (uint)
    {
        if (!this.hasValidProfile(userAddress)) {
            return 0;
        } else {
            KYC storage kyc = records[userAddress];
            return kyc.verifiedAttributes;
        }
    }


    function claim(address verifier, uint verifiedAttributes, uint expires, uint8 v, bytes32 r, bytes32 s)
      public
      onlyValidAuthority(verifier)
      onlyAuthoritativeAuthority(verifier, msg.sender)
    {
        // Payment
        if (verificationFee > 0) {
            if(!chargeVerificationFee(msg.sender, verifier)) {
                revert();
            }
        }

        // Signature verification
        bytes32 hash = sha256(this, msg.sender, verifiedAttributes, expires);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, hash);

        if (!((ecrecover(prefixedHash, v, r, s) == verifier) && block.number <= expires)) {
            revert();
        }

        // Record

        KYC memory kyc = KYC({
            verified: true,
            verifiedBy: verifier,
            verifiedAt: block.number,
            verifiedAttributes: verifiedAttributes
        });

        records[msg.sender] = kyc;
    }

    function approve(address userAddress, uint verifiedAttributes)
      public
      onlyValidAuthority(msg.sender)
      onlyAuthoritativeAuthority(msg.sender, userAddress)
    {
        // Record
        KYC memory kyc = KYC({
            verified: true,
            verifiedBy: msg.sender,
            verifiedAt: block.number,
            verifiedAttributes: verifiedAttributes
        });

        records[userAddress] = kyc;
    }

    function revoke(address userAddress)
      public
      onlyValidAuthority(msg.sender)
      onlyAuthoritativeAuthority(msg.sender, userAddress)
    {
        // Revoke
        KYC memory kyc = KYC({
            verified: false,
            verifiedBy: msg.sender,
            verifiedAt: block.number,
            verifiedAttributes: 0
        });

        records[userAddress] = kyc;
    }
}