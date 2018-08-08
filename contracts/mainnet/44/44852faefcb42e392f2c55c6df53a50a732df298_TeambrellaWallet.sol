pragma solidity ^0.4.19;

contract TeambrellaWallet {
    
    uint public m_opNum;
    uint public m_teamId;
    address public m_owner;
    address[] public m_cosigners;
    address[] public m_cosignersApprovedDisband;    
    
    modifier orderedOps(uint opNum) {
        require(opNum >= m_opNum);
        _; 
    }

    modifier onlyOwner {
        require(msg.sender == m_owner);
        _; 
    }
    
    function() public payable { }


    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    function ecrecovery(bytes32 hash, bytes sig) private returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
            // v := and(mload(add(sig, 65)), 255)
        }

        return safer_ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) private returns (bool) {
        bool ret;
        address addr;

        (ret, addr) = ecrecovery(hash, sig);

        return ret == true && addr == signer;
    }

    function checkSignatures(
        bytes32 hash,
        uint[3] cosignersPos,
        bytes sigCosigner0,
        bytes sigCosigner1,
        bytes sigCosigner2
        ) private returns(bool) {

        uint cosignersNum = m_cosigners.length;
        bool signed = ecverify(hash, sigCosigner0, m_cosigners[cosignersPos[0]]);
        if (cosignersNum > 3) {
            signed = signed && ecverify(hash, sigCosigner1, m_cosigners[cosignersPos[1]]);
        }
        if (cosignersNum > 6) {
            signed = signed && ecverify(hash, sigCosigner2, m_cosigners[cosignersPos[2]]);
        }

        return signed;
    }
    
    function checkSignatures2(
        bytes32 hash,
        bytes sigCosigner0,
        bytes sigCosigner1,
        bytes sigCosigner2
        ) private returns(bool) {

        uint cosignersNum = m_cosigners.length;
        uint pos = uint(sigCosigner0[65]);
        bool signed = ecverify(hash, sigCosigner0, m_cosigners[pos]);
        if (cosignersNum > 3) {
            pos = uint(sigCosigner1[65]);
            signed = signed && ecverify(hash, sigCosigner1, m_cosigners[pos]);
        }
        if (cosignersNum > 6) {
            pos = uint(sigCosigner2[65]);
            signed = signed && ecverify(hash, sigCosigner2, m_cosigners[pos]);
        }
        return signed;
    }

    function toBytes(uint256[] x) private pure returns (bytes b) {
        b = new bytes(32 * x.length);
        for (uint j = 0; j < x.length; j++) {
            for (uint i = 0; i < 32; i++) {
                b[j*32 + i] = byte(uint8(x[j] / (2**(8*(31 - i))))); 
            }
        }
    }

    function toBytes(address[] x) private pure returns (bytes b) {

        b = new bytes(20 * x.length);
        for (uint j = 0; j < x.length; j++) {
            for (uint i = 0; i < 20; i++) {
                b[j*20 + i] = byte(uint8(uint160(x[j]) / (2**(8*(19 - i))))); 
            }
        }
    }

    function TeambrellaWallet() public payable {
        m_opNum = 1;
		m_owner = msg.sender;
    }
    
     function assignOwner(address[] cosigners, uint teamId, address newOwner) onlyOwner external {
		if (m_cosigners.length == 0)
		{
			m_cosigners = cosigners;
			m_teamId = teamId;
			m_owner = newOwner;
		}
    }
       
    function changeAllCosigners(
        uint opNum,
        address[] newCosigners,
        uint[3] cosignersPos,
        bytes sigCosigner0, 
        bytes sigCosigner1,
        bytes sigCosigner2 
        ) onlyOwner orderedOps(opNum) external {

        bytes32 hash = keccak256("NS", m_teamId, opNum, toBytes(newCosigners));
        require(checkSignatures(hash, cosignersPos, sigCosigner0, sigCosigner1, sigCosigner2));
        m_opNum = opNum + 1;
        m_cosignersApprovedDisband.length = 0;
        m_cosigners = newCosigners;
    }

    function changeAllCosigners2(
        uint opNum,
        address[] newCosigners,
        bytes sigCosigner0, 
        bytes sigCosigner1,
        bytes sigCosigner2,
        bytes sigOwner 
        ) onlyOwner orderedOps(opNum) external {

        bytes32 hash = keccak256("NS", m_teamId, opNum, toBytes(newCosigners));
        require(checkSignatures2(hash, sigCosigner0, sigCosigner1, sigCosigner2));
        require(ecverify(hash, sigOwner, m_owner));
        m_opNum = opNum + 1;
        m_cosignersApprovedDisband.length = 0;
        m_cosigners = newCosigners;
    }
        
    function getsum(uint[] values) private pure returns (uint s) {
        s = 0;

        for (uint j = 0; j < values.length; j++) {
            s += values[j];
        }

        return s;    
    }
        
    function transfer(
        uint opNum,
        address[] tos, 
        uint[] values,
        uint[3] cosignersPos,
        bytes sigCosigner0, 
        bytes sigCosigner1, 
        bytes sigCosigner2
        ) onlyOwner orderedOps(opNum) external {

        require (getsum(values) <= this.balance);
        bytes32 hash = keccak256("TR", m_teamId, opNum, toBytes(tos), toBytes(values));
        require (checkSignatures(hash, cosignersPos, sigCosigner0, sigCosigner1, sigCosigner2));
        m_opNum = opNum + 1;
        realtransfer(tos, values);
    }

    function transfer2(
        uint opNum,
        address[] tos, 
        uint[] values,
        bytes sigCosigner0,
        bytes sigCosigner1,
        bytes sigCosigner2,
        bytes sigOwner
        ) external {
        require(opNum >= m_opNum);
        require (getsum(values) <= this.balance);
        bytes32 hash = keccak256("TR", m_teamId, opNum, toBytes(tos), toBytes(values));
        require(checkSignatures2(hash, sigCosigner0, sigCosigner1, sigCosigner2));
        require(ecverify(hash, sigOwner, m_owner));
        m_opNum = opNum + 1;
        realtransfer(tos, values);
    }    

    function realtransfer(address[] tos, uint[] values) private {

        for (uint i = 0; i < values.length; i++) {
            tos[i].transfer(values[i]);
        }
    }

    function approveDisband() external {

        for (uint pos=0; pos<m_cosignersApprovedDisband.length; pos++) {
            if (m_cosignersApprovedDisband[pos] == msg.sender) {
                return;
            }
        }
        for (pos=0; pos<m_cosigners.length; pos++) {
            if (m_cosigners[pos] == msg.sender) {
                m_cosignersApprovedDisband.push(msg.sender);
            }
        }
    }

    function disbandTo(address to) onlyOwner external {

        uint cosignersNum = m_cosigners.length;
        uint approved = m_cosignersApprovedDisband.length;
        if (cosignersNum > 6) {
            require(approved > 2);
        }
        if (cosignersNum > 3) {
            require(approved > 1);
        }
        require(approved > 0);

        to.transfer(this.balance);
    }
}