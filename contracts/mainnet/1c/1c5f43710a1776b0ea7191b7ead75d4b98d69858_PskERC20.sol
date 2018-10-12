pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract PskERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    // Locked address mapping
    mapping (address => uint256) public lockedUntil;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    /**
     * Constructor function
     */
    function PskERC20() public {
        uint256 initialSupply = 68072143;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        name = &#39;Pool of Stake Master Token&#39;;
        symbol = &#39;PSK&#39;;
        balanceOf[address(this)] = totalSupply;
        emit Transfer(address(this), address(this), totalSupply);
        // Launch Transfers
        _transfer(address(this),0x8b89dc977c1D4e1B78803342487dEcee0a2Ba02c,378000000000000000000000);
        _transfer(address(this),0xC19c9dd81D4b8B3FaDE83eEF6f2863Ac9B76B7FB,34912500000000000000000);
        _transfer(address(this),0x5Ea29C0a72Ab68bE62c7942d5b3aD69d4f29d4dA,1640625000000000000000000);
        _transfer(address(this),0x14a926e168278cC0c00286837de51e29F814b8D3,12250000000000000000000);
        _transfer(address(this),0xD46d9fE2d8f991913Bd4f77536abBa4598EA29A9,131250000000000000000000);
        _transfer(address(this),0x0019312D39a13302Fbacedf995f702F6e071D9e8,175000000000000000000000);
        _transfer(address(this),0x0FBd0E32aFE5082FED52837d96df7E34a9252bC3,8750000000000000000000);
        _transfer(address(this),0x10E6a8f9Dbe3A6BF4aB8D07233A45125Fb411eF1,5250000000000000000000);
        _transfer(address(this),0x93ED3C6a78724308095C34eFD0dcdA693f515BE7,1750000000000000000000);
        _transfer(address(this),0xd113f63Fec7F296FFE838939Bfd3775339d79e44,3500000000000000000000);
        _transfer(address(this),0x83aCbBE5f22841799647De7c4aC9f0fa61691975,87500000000000000000000);
        _transfer(address(this),0xEfFefF8De1C5f15FE6545a32C1Aaa372c6023d77,1750000000000000000000);
        _transfer(address(this),0xEfFefF8De1C5f15FE6545a32C1Aaa372c6023d77,1750000000000000000000);
        _transfer(address(this),0xEfFefF8De1C5f15FE6545a32C1Aaa372c6023d77,49000000000000000000000);
        _transfer(address(this),0x5239249C90D0c31C9F2A861af4da7E3393399Cb9,8750000000000000000000);
        _transfer(address(this),0x9b818b7B401908671CbE2bf677F7F3361653Fdb5,28526399998250000000000);
        _transfer(address(this),0x55A0B2b1A705dD09F15e7120cC0c39ACb9Ea7978,35000000000000000000000);
        _transfer(address(this),0x8a501A75eE3d0C808b39dd2bc2760289F9785500,3500000000000000000000);
        _transfer(address(this),0x752452F7759E58C50A7817F616B5317275924F78,272144811750000000000);
        _transfer(address(this),0x639631fc10eA37DF5540E3A6FAf1Bd12Ab02A02c,28000000000000000000000);
        _transfer(address(this),0x8A0Dea5F511b21a58aC9b2E348eB80E19B7126ab,98000000000000000000000);
        _transfer(address(this),0x231A9614c5726df24BB385F4A1720d6408302fde,42000000000000000000000);
        _transfer(address(this),0xCE2daE844a2f473Cb10e72eA5B5cd82ce1C86c76,207900000000000000000);
        _transfer(address(this),0x9829D08FE48a402fF1A3e9faD0407023ffd947e7,1890000000000000000000);
        _transfer(address(this),0xd495826cABB093e7dCA498D1a98e4dc55e0C29Db,5670000000000000000000);
        _transfer(address(this),0x7C31755f9374c238248aD19EABf648c79FF3A5eD,945000000000000000000);
        _transfer(address(this),0x9Ce1B1B62344ADdca64Aac6338da369f395367DE,5670000000000000000000);
        _transfer(address(this),0x81a1Ff97AE6DB89f5FD1B0Fb559Bd7C61e4BA960,189000000000000000000);
        _transfer(address(this),0xd4E6c27B8e5805318295f3586F59c34B60495992,1890000000000000000000);
        _transfer(address(this),0xc458F28FC72bA8dFEE6021763eCAAF21033839e8,3780000000000000000000);
        _transfer(address(this),0x2188f6212CE37dCbfeC7e0167D68d9e5E5F07e3a,1890000000000000000000);
        _transfer(address(this),0xd1EfE47c8610678DE2192F03B8dA49b25Be746fb,5670000000000000000000);
        _transfer(address(this),0x7967149ed2FBaA14D1E74D26505573C803c0D698,473185571040000000000);
        _transfer(address(this),0x7967149ed2FBaA14D1E74D26505573C803c0D698,463050000000000000000);
        _transfer(address(this),0x5BFd06c00CCf7c25984D1Fb4D153Abfdb999984c,189000000000000000000);
        _transfer(address(this),0xAAA0779B11BC0b03f00F82427f4C14F9C2dBB6aB,2835000000000000000000);
        _transfer(address(this),0x4DE5BA1869Dfd12eE429eE227EAEa33b295AE7C9,378000000000000000000);
        _transfer(address(this),0xA4C8ed0dB08a9EfCc502f390E5E75c51851B870A,623700000000000000000);
        _transfer(address(this),0xbA6F61ca597510E8dc86c7f3e4fe1d251e8C5B89,642600000000000000000);
        _transfer(address(this),0x1a08bac3FA02C1aC7e12F8b961e3B2ed6CE31E00,18879909300000000000000);
        _transfer(address(this),0x4745b5130aC32Ed0c541442440C37284d475a166,2627100000000000000000);
        _transfer(address(this),0xd00266409A2fd099FEcbFd0340F7A965CeeceCF2,378000000000000000000);
        _transfer(address(this),0x26C0E0772EA9ABd416667ee5FFf978cb1F54720A,1890000000000000000000);
        _transfer(address(this),0x2874E22Bb3a2E378cabaa1058Aa09a23087829d0,283500000000000000000);
        _transfer(address(this),0x19682FE3B7BB4D0Baba4c53fa1C697c9Ba2Fce02,75600000000000000000000);
        _transfer(address(this),0xA4C8ed0dB08a9EfCc502f390E5E75c51851B870A,1341900000000000000000);
        _transfer(address(this),0x9ED09BD3c7BB325cCb84D793Ad9ce42a068D7Ef1,3780000000000000000000);
        _transfer(address(this),0x0b72805FFa5CB6E1187223e8EEF97dA6a6a0950c,5670000000000000000000);
        _transfer(address(this),0xe19938a75140d8e16aF4bf5F08D97B4cd8C62317,3780000000000000000000);
        _transfer(address(this),0xEf4a2C6b92024E359e107Aa6Acd17F6391855B5a,618030000000000000000);
        _transfer(address(this),0x7967149ed2FBaA14D1E74D26505573C803c0D698,563846285520000000000);
        _transfer(address(this),0x446471EAc3Ac288b9bECb3ca814daefEB867Bbc8,472500000000000000000);
        _transfer(address(this),0xd89F659402245781daC5c11CBaBB86B79484E696,94500000000000000000000);
        _transfer(address(this),0x8252e834763933124f80177b08e6F60A90DA0919,1890000000000000000000);
        _transfer(address(this),0xD996263209B2dfbA4Bbba5D7F37705DdE265116E,2800000000000000000000);
        _transfer(address(this),0x664f129b55a6948900577bad77D9b6a792b50743,140000000000000000000);
        _transfer(address(this),0x8166AD8690A3E7BFb2D6B45006eBB5d111628a59,663452885200000000000);
        _transfer(address(this),0x4997DF0Ef9f05A5c136f991b5ee088BBF5526f42,423906000000000000000);
        _transfer(address(this),0xA823648A8251B44b09873723A32831f2f206acD5,554483286000000000000);
        _transfer(address(this),0x7CDE9cD90afaEc5a40480DDA05C8Cf4ec39cF643,140000000000000000000);
        _transfer(address(this),0x0f929995C0c8a00E212dF802f57b5f63D7640FE7,8400000000000000000000);
        _transfer(address(this),0x1e7D081e2Bf261F99918d02366ed8F3B524e39EC,840000000000000000000);
        _transfer(address(this),0x0354dEd5058c5AB4aa42F8260c2Cc08904e7eE09,329000000000000000000);
        _transfer(address(this),0x73b3166784F4C878E6eea15665F6F35651141984,294000000000000000000);
        _transfer(address(this),0x6133c06Be78f1D2AB67b4cd8f854C90167dBd066,680000000000000000000000);
        _transfer(address(this),0xFf342491cC946B8Cd9d7B48484306a0C18B814Dd,416666666666667000000000);
        _transfer(address(this),0x4fd60c47bf9437954557d0Ec46C68B63858B2862,3900000000000000000000);
        _transfer(address(this),0xD384C81eFEF96CB32Ae8Ad52cC85630eABC75E26,3024002711476670000000000);
        _transfer(address(this),0x820baEBb0f077C746DaF57af4DCD38bEACeE22ed,100000000000000000000);
        _transfer(address(this),0x13A7b665c91259873dFF9D685811Bc916b5E403c,100000000000000000000);
        _transfer(address(this),0xBa122378B1b5A5D73B2778Aa6C724c4D43ebf966,100000000000000000000);
        _transfer(address(this),0xd495826cABB093e7dCA498D1a98e4dc55e0C29Db,100000000000000000000);
        _transfer(address(this),0x3dC21E7Eca79C7b9890dF4AFbe2E0ba2f17512C3,100000000000000000000);
        _transfer(address(this),0xA823648A8251B44b09873723A32831f2f206acD5,100000000000000000000);
        _transfer(address(this),0x68b1951F36e77324924170cAE9Ca2aa03dc1e0AC,100000000000000000000);
        _transfer(address(this),0x1CE853FC613D900FD9eB004d2D7837E97D40a23C,100000000000000000000);
        _transfer(address(this),0x0AeEe2337F2Cc88AB7cadc619205b22C7Ee2f05A,100000000000000000000);
        _transfer(address(this),0x4C844FEf1014bE0862167925842c4835354Dc4B6,100000000000000000000);
        _transfer(address(this),0x24f56B8e6b0bc478c00a8055600BA076777c5cFa,100000000000000000000);
        _transfer(address(this),0xDe29bB2E66F1731B187919bB34f4Dd793CebbE86,100000000000000000000);
        _transfer(address(this),0xE792690B3783c08823049b1DCe5CC916001e92Cd,340000000000000000000000);
        _transfer(address(this),0x08a62f6DFd9f4334478B5CC038d0584fEACe9ac8,340000000000000000000000);
        _transfer(address(this),0xd987728d110e0A270dc4B6E75e558E0F29E0c2c7,340000000000000000000000);
        _transfer(address(this),0x25A8178d085a600Eb535e51D3bCD4Fea773E81e4,650000000000000000000000);
        _transfer(address(this),0xE9cB39c9AfCf84C73FB3e8E8a3353d0bfD2Baa0F,750000000000000000000000);
        _transfer(address(this),0xa537E2887B9887Cb72bDd381C9E21DA4856bb60d,382000000000000000000000);
        _transfer(address(this),0x1d4Aa2b232Af68599864efE1C0Fbf4F4b5E6112c,510500000000000000000000);
        _transfer(address(this),0xCbEde66A699C3a5efF63c5E234D7b8149f353c4E,397500000000000000000000);
        _transfer(address(this),0xf2944172b735609b2EcEeadb00179AC88f6aA431,630000000000000000000000);
        _transfer(address(this),0x3e6330A1a05a170b16Dabfb2ECe7E44453CD5A36,2333333333333320000000000);
        _transfer(address(this),0x21028AAeb61f39c68380928e7d6297C47d09CdD9,3466666666666660000000000);
        _transfer(address(this),0x98Dc9E2b1AA2A29D71eec988e45022Ad774f6bF6,2000000000000000000000000);
        _transfer(address(this),0xdc3603FB59BDb00A527c9D8143Cda58d3A1Ade8d,1866666666666670000000000);
        _transfer(address(this),0xE85D25FA06b045396C2Ce811F461d3e408DcD267,2666666666666660000000000);
        _transfer(address(this),0x79A69503eC313cAf56A83Ff05A9C5a7798504eD4,1000000000000000000000000);
        _transfer(address(this),0x0B4Db8D4e13EeB6aac5D2e7fB770Ac118bDE8dc6,1666666666666670000000000);
        _transfer(address(this),0xD6d957139941af45B452b69783A19C77a6883ea8,1733333333333330000000000);
        _transfer(address(this),0x237Abf82405C542A803642DbbbFA9639Df9cA33D,2933333333333320000000000);
        _transfer(address(this),0x78961633419f69032D874c27D1d789E243c2B8Ed,333333333333332000000000);
        _transfer(address(this),0xB62FD8775e4938A352cb20E632654CC2f5e76829,564202334630000000000);
        _transfer(address(this),0x1449dEb2db6dFD95299776E3F77aCe0ffFFD0198,225225225230000000000);
        _transfer(address(this),0xa77694c0C0d0e81Ca1a21c8A6498bb2c0A1329f2,1922178988330000000000);
        _transfer(address(this),0xD996263209B2dfbA4Bbba5D7F37705DdE265116E,10000000000000000000000);
        _transfer(address(this),0xa854fF673bf41Cf79c2E4C799Af94d5f275D8D5e,333333333330000000000);
        _transfer(address(this),0x3353bfCA0DF0C585E94b2eE2338572f46c8986Dd,1000000000000000000000);
        _transfer(address(this),0x72417A054Efa81d50252cC5ceCc58716cdD99Ac7,149880000000000000000000);
        _transfer(address(this),0xB16e325f3458d8A6658b5f69e7986686428Ecf58,1426866000000000000000000);
        _transfer(address(this),0xd1eFcC88EFBEAe11FF3F2dF5A49B24D519cdBbf2,857144000000000000000000);
        _transfer(address(this),0x6517f439AD90ecAc307EC543404D998C0Ec965B6,2000000000000000000000000);
        _transfer(address(this),0x87a4E93f1acCf6dcf536107d9786d3b344D2ec05,1666667000000000000000000);
        _transfer(address(this),0xbDba9C3E780FB6AF27FD964e2c861b35deE0c318,3000000000000000000000000);
        _transfer(address(this),0xaBeEa80693B860ae2C47F824A8fDAD402AEbE100,2500000000000000000000000);
        _transfer(address(this),0xB83dB1E8E14A7A40BB62F2A8EBce5BBD07EA3F62,1666666666666660000000000);
        _transfer(address(this),0x51f96736Bbc6348cbF33A224C3Cc5231A87a1e43,2000000000000000000000000);
        _transfer(address(this),0x2FBE4cdb2f46dc12d86A1289323a7D0545Fe2b5e,5000000000000000000000000);
        _transfer(address(this),0xF062193f4f34Ac4A13BAdd1bB8e7E4132637C1E7,3500000907170760000000000);
        _transfer(address(this),0x4ed9001076B69e19b397aC719D235F4f0786D7C5,4079000000000000000000000);
        _transfer(address(this),0x7A52a16f34576CBc028c1840825cDa9323DA4890,2268334000000000000000000);
        _transfer(address(this),0x5AA37C6176b6E0612151BE56A8a0372C9DB7DE90,2268334000000000000000000);
        _transfer(address(this),0x7518d5cB06891C62621871b1aC3bdE500BD533a0,2268334000000000000000000);
        _transfer(address(this),0xA3f3f84844A67c618DE06441d2970321e70bdCe7,700000000000000000000000);
        _transfer(address(this),0xBEc13832bb518629501fe7d07caAB099E85e1c50,700000000000000000000000);
        _transfer(address(this),0xF6F209C6C031b1560D073d5E82b380C40cD02469,300000000000000000000000);
        _transfer(address(this),0xf0586C3e0CAe135E90dDe857b5f53C8B29Ebc77c,55500000000000000000000);
        _transfer(address(this),0x9b818b7B401908671CbE2bf677F7F3361653Fdb5,35000000000000000000000);
        _transfer(address(this),0xd5C56952e1Aad42f20075666b123F42334969297,30000000000000000000000);
        _transfer(address(this),0xB6ceCEAbfBd07ac0440972C0c0c4129249de29Da,45000000000000000000000);
        _transfer(address(this),0x0eaa51bef06694e1e0C99f413dcd7d3beE110Fb9,40000000000000000000000);

        // Locked addresses
        lockedUntil[0xD384C81eFEF96CB32Ae8Ad52cC85630eABC75E26]=1554508800;
        lockedUntil[0xE792690B3783c08823049b1DCe5CC916001e92Cd]=1570320000;
        lockedUntil[0x08a62f6DFd9f4334478B5CC038d0584fEACe9ac8]=1570320000;
        lockedUntil[0xd987728d110e0A270dc4B6E75e558E0F29E0c2c7]=1570320000;
        lockedUntil[0x25A8178d085a600Eb535e51D3bCD4Fea773E81e4]=1554508800;
        lockedUntil[0xE9cB39c9AfCf84C73FB3e8E8a3353d0bfD2Baa0F]=1554508800;
        lockedUntil[0x1d4Aa2b232Af68599864efE1C0Fbf4F4b5E6112c]=1554508800;
        lockedUntil[0xCbEde66A699C3a5efF63c5E234D7b8149f353c4E]=1570320000;
        lockedUntil[0xf2944172b735609b2EcEeadb00179AC88f6aA431]=1554508800;
        lockedUntil[0x2FBE4cdb2f46dc12d86A1289323a7D0545Fe2b5e]=1554508800;
        lockedUntil[0x7A52a16f34576CBc028c1840825cDa9323DA4890]=1601942400;
        lockedUntil[0x5AA37C6176b6E0612151BE56A8a0372C9DB7DE90]=1601942400;
        lockedUntil[0x7518d5cB06891C62621871b1aC3bdE500BD533a0]=1601942400;
        lockedUntil[0xA3f3f84844A67c618DE06441d2970321e70bdCe7]=1554508800;
        lockedUntil[0xBEc13832bb518629501fe7d07caAB099E85e1c50]=1554508800;
        lockedUntil[0xF6F209C6C031b1560D073d5E82b380C40cD02469]=1570320000;
        lockedUntil[0xf0586C3e0CAe135E90dDe857b5f53C8B29Ebc77c]=1570320000;
        lockedUntil[0x9b818b7B401908671CbE2bf677F7F3361653Fdb5]=1554508800;
        lockedUntil[0xd5C56952e1Aad42f20075666b123F42334969297]=1554508800;
        lockedUntil[0xB6ceCEAbfBd07ac0440972C0c0c4129249de29Da]=1554508800;
        lockedUntil[0x0eaa51bef06694e1e0C99f413dcd7d3beE110Fb9]=1554508800;

    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {

        // assert locked addresses
        assert( lockedUntil[_from] == 0 ||  (lockedUntil[_from] != 0 && block.timestamp >= lockedUntil[_from]) );
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}