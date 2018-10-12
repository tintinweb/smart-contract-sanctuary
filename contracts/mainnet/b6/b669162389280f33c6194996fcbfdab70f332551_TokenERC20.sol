pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
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
    function TokenERC20(
    ) public {
        uint256 initialSupply = 68072143;
        totalSupply = initialSupply * 10 ** uint256(decimals);
        name = &#39;Pool of Stake&#39;;
        symbol = &#39;PSK&#39;;

        // Init balances
        balanceOf[0x8b89dc977c1d4e1b78803342487decee0a2ba02c]=378000000000000000000000;
        balanceOf[0xc19c9dd81d4b8b3fade83eef6f2863ac9b76b7fb]=34912500000000000000000;
        balanceOf[0x5ea29c0a72ab68be62c7942d5b3ad69d4f29d4da]=1640625000000000000000000;
        balanceOf[0x14a926e168278cc0c00286837de51e29f814b8d3]=12250000000000000000000;
        balanceOf[0xd46d9fe2d8f991913bd4f77536abba4598ea29a9]=131250000000000000000000;
        balanceOf[0x0019312d39a13302fbacedf995f702f6e071d9e8]=175000000000000000000000;
        balanceOf[0x0fbd0e32afe5082fed52837d96df7e34a9252bc3]=8750000000000000000000;
        balanceOf[0x10e6a8f9dbe3a6bf4ab8d07233a45125fb411ef1]=5250000000000000000000;
        balanceOf[0x93ed3c6a78724308095c34efd0dcda693f515be7]=1750000000000000000000;
        balanceOf[0xd113f63fec7f296ffe838939bfd3775339d79e44]=3500000000000000000000;
        balanceOf[0x83acbbe5f22841799647de7c4ac9f0fa61691975]=87500000000000000000000;
        balanceOf[0xeffeff8de1c5f15fe6545a32c1aaa372c6023d77]=1750000000000000000000;
        balanceOf[0xeffeff8de1c5f15fe6545a32c1aaa372c6023d77]=1750000000000000000000;
        balanceOf[0xeffeff8de1c5f15fe6545a32c1aaa372c6023d77]=49000000000000000000000;
        balanceOf[0x5239249c90d0c31c9f2a861af4da7e3393399cb9]=8750000000000000000000;
        balanceOf[0x9b818b7b401908671cbe2bf677f7f3361653fdb5]=28526399998250000000000;
        balanceOf[0x55a0b2b1a705dd09f15e7120cc0c39acb9ea7978]=35000000000000000000000;
        balanceOf[0x8a501a75ee3d0c808b39dd2bc2760289f9785500]=3500000000000000000000;
        balanceOf[0x752452f7759e58c50a7817f616b5317275924f78]=272144811750000000000;
        balanceOf[0x639631fc10eA37DF5540E3A6FAf1Bd12Ab02A02c]=28000000000000000000000;
        balanceOf[0x8A0Dea5F511b21a58aC9b2E348eB80E19B7126ab]=98000000000000000000000;
        balanceOf[0x231A9614c5726df24BB385F4A1720d6408302fde]=42000000000000000000000;
        balanceOf[0xce2dae844a2f473cb10e72ea5b5cd82ce1c86c76]=207900000000000000000;
        balanceOf[0x9829d08fe48a402ff1a3e9fad0407023ffd947e7]=1890000000000000000000;
        balanceOf[0xd495826cabb093e7dca498d1a98e4dc55e0c29db]=5670000000000000000000;
        balanceOf[0x7c31755f9374c238248ad19eabf648c79ff3a5ed]=945000000000000000000;
        balanceOf[0x9ce1b1b62344addca64aac6338da369f395367de]=5670000000000000000000;
        balanceOf[0x81a1ff97ae6db89f5fd1b0fb559bd7c61e4ba960]=189000000000000000000;
        balanceOf[0xd4e6c27b8e5805318295f3586f59c34b60495992]=1890000000000000000000;
        balanceOf[0xc458f28fc72ba8dfee6021763ecaaf21033839e8]=3780000000000000000000;
        balanceOf[0x2188f6212ce37dcbfec7e0167d68d9e5e5f07e3a]=1890000000000000000000;
        balanceOf[0xd1efe47c8610678de2192f03b8da49b25be746fb]=5670000000000000000000;
        balanceOf[0x7967149ed2fbaa14d1e74d26505573c803c0d698]=473185571040000000000;
        balanceOf[0x7967149ed2fbaa14d1e74d26505573c803c0d698]=463050000000000000000;
        balanceOf[0x5bfd06c00ccf7c25984d1fb4d153abfdb999984c]=189000000000000000000;
        balanceOf[0xaaa0779b11bc0b03f00f82427f4c14f9c2dbb6ab]=2835000000000000000000;
        balanceOf[0x4de5ba1869dfd12ee429ee227eaea33b295ae7c9]=378000000000000000000;
        balanceOf[0xa4c8ed0db08a9efcc502f390e5e75c51851b870a]=623700000000000000000;
        balanceOf[0xba6f61ca597510e8dc86c7f3e4fe1d251e8c5b89]=642600000000000000000;
        balanceOf[0x1a08bac3fa02c1ac7e12f8b961e3b2ed6ce31e00]=18879909300000000000000;
        balanceOf[0x4745b5130ac32ed0c541442440c37284d475a166]=2627100000000000000000;
        balanceOf[0xd00266409a2fd099fecbfd0340f7a965ceececf2]=378000000000000000000;
        balanceOf[0x26c0e0772ea9abd416667ee5fff978cb1f54720a]=1890000000000000000000;
        balanceOf[0x2874e22bb3a2e378cabaa1058aa09a23087829d0]=283500000000000000000;
        balanceOf[0x19682fe3b7bb4d0baba4c53fa1c697c9ba2fce02]=75600000000000000000000;
        balanceOf[0xa4c8ed0db08a9efcc502f390e5e75c51851b870a]=1341900000000000000000;
        balanceOf[0x9ed09bd3c7bb325ccb84d793ad9ce42a068d7ef1]=3780000000000000000000;
        balanceOf[0x0b72805ffa5cb6e1187223e8eef97da6a6a0950c]=5670000000000000000000;
        balanceOf[0xe19938a75140d8e16af4bf5f08d97b4cd8c62317]=3780000000000000000000;
        balanceOf[0xef4a2c6b92024e359e107aa6acd17f6391855b5a]=618030000000000000000;
        balanceOf[0x7967149ed2fbaa14d1e74d26505573c803c0d698]=563846285520000000000;
        balanceOf[0x446471eac3ac288b9becb3ca814daefeb867bbc8]=472500000000000000000;
        balanceOf[0xd89f659402245781dac5c11cbabb86b79484e696]=94500000000000000000000;
        balanceOf[0x8252e834763933124f80177b08e6f60a90da0919]=1890000000000000000000;
        balanceOf[0xd996263209b2dfba4bbba5d7f37705dde265116e]=2800000000000000000000;
        balanceOf[0x664f129b55a6948900577bad77d9b6a792b50743]=140000000000000000000;
        balanceOf[0x8166ad8690a3e7bfb2d6b45006ebb5d111628a59]=663452885200000000000;
        balanceOf[0x4997df0ef9f05a5c136f991b5ee088bbf5526f42]=423906000000000000000;
        balanceOf[0xa823648a8251b44b09873723a32831f2f206acd5]=554483286000000000000;
        balanceOf[0x7cde9cd90afaec5a40480dda05c8cf4ec39cf643]=140000000000000000000;
        balanceOf[0x0f929995c0c8a00e212df802f57b5f63d7640fe7]=8400000000000000000000;
        balanceOf[0x1e7d081e2bf261f99918d02366ed8f3b524e39ec]=840000000000000000000;
        balanceOf[0x0354ded5058c5ab4aa42f8260c2cc08904e7ee09]=329000000000000000000;
        balanceOf[0x73b3166784f4c878e6eea15665f6f35651141984]=294000000000000000000;
        balanceOf[0x6133c06Be78f1D2AB67b4cd8f854C90167dBd066]=680000000000000000000000;
        balanceOf[0xFf342491cC946B8Cd9d7B48484306a0C18B814Dd]=416666666666667000000000;
        balanceOf[0x4fd60c47bf9437954557d0Ec46C68B63858B2862]=3900000000000000000000;
        balanceOf[0xD384C81eFEF96CB32Ae8Ad52cC85630eABC75E26]=3024002711476670000000000;
        balanceOf[0x820baEBb0f077C746DaF57af4DCD38bEACeE22ed]=100000000000000000000;
        balanceOf[0x13A7b665c91259873dFF9D685811Bc916b5E403c]=100000000000000000000;
        balanceOf[0xba122378b1b5a5d73b2778aa6c724c4d43ebf966]=100000000000000000000;
        balanceOf[0xd495826cABB093e7dCA498D1a98e4dc55e0C29Db]=100000000000000000000;
        balanceOf[0x3dC21E7Eca79C7b9890dF4AFbe2E0ba2f17512C3]=100000000000000000000;
        balanceOf[0xA823648A8251B44b09873723A32831f2f206acD5]=100000000000000000000;
        balanceOf[0x68b1951F36e77324924170cAE9Ca2aa03dc1e0AC]=100000000000000000000;
        balanceOf[0x1ce853fc613d900fd9eb004d2d7837e97d40a23c]=100000000000000000000;
        balanceOf[0x0AeEe2337F2Cc88AB7cadc619205b22C7Ee2f05A]=100000000000000000000;
        balanceOf[0x4C844FEf1014bE0862167925842c4835354Dc4B6]=100000000000000000000;
        balanceOf[0x24f56B8e6b0bc478c00a8055600BA076777c5cFa]=100000000000000000000;
        balanceOf[0xDe29bB2E66F1731B187919bB34f4Dd793CebbE86]=100000000000000000000;
        balanceOf[0xE792690B3783c08823049b1DCe5CC916001e92Cd]=340000000000000000000000;
        balanceOf[0x08a62f6DFd9f4334478B5CC038d0584fEACe9ac8]=340000000000000000000000;
        balanceOf[0xd987728d110e0A270dc4B6E75e558E0F29E0c2c7]=340000000000000000000000;
        balanceOf[0x25A8178d085a600Eb535e51D3bCD4Fea773E81e4]=650000000000000000000000;
        balanceOf[0xE9cB39c9AfCf84C73FB3e8E8a3353d0bfD2Baa0F]=750000000000000000000000;
        balanceOf[0xa537E2887B9887Cb72bDd381C9E21DA4856bb60d]=382000000000000000000000;
        balanceOf[0x1d4Aa2b232Af68599864efE1C0Fbf4F4b5E6112c]=510500000000000000000000;
        balanceOf[0xCbEde66A699C3a5efF63c5E234D7b8149f353c4E]=397500000000000000000000;
        balanceOf[0xf2944172b735609b2EcEeadb00179AC88f6aA431]=630000000000000000000000;
        balanceOf[0x3e6330A1a05a170b16Dabfb2ECe7E44453CD5A36]=2333333333333320000000000;
        balanceOf[0x21028AAeb61f39c68380928e7d6297C47d09CdD9]=3466666666666660000000000;
        balanceOf[0x98Dc9E2b1AA2A29D71eec988e45022Ad774f6bF6]=2000000000000000000000000;
        balanceOf[0xdc3603FB59BDb00A527c9D8143Cda58d3A1Ade8d]=1866666666666670000000000;
        balanceOf[0xE85D25FA06b045396C2Ce811F461d3e408DcD267]=2666666666666660000000000;
        balanceOf[0x79A69503eC313cAf56A83Ff05A9C5a7798504eD4]=1000000000000000000000000;
        balanceOf[0x0B4Db8D4e13EeB6aac5D2e7fB770Ac118bDE8dc6]=1666666666666670000000000;
        balanceOf[0xD6d957139941af45B452b69783A19C77a6883ea8]=1733333333333330000000000;
        balanceOf[0x237Abf82405C542A803642DbbbFA9639Df9cA33D]=2933333333333320000000000;
        balanceOf[0x78961633419f69032D874c27D1d789E243c2B8Ed]=333333333333332000000000;
        balanceOf[0xB62FD8775e4938A352cb20E632654CC2f5e76829]=564202334630000000000;
        balanceOf[0x1449dEb2db6dFD95299776E3F77aCe0ffFFD0198]=225225225230000000000;
        balanceOf[0xa77694c0C0d0e81Ca1a21c8A6498bb2c0A1329f2]=1922178988330000000000;
        balanceOf[0xD996263209B2dfbA4Bbba5D7F37705DdE265116E]=10000000000000000000000;
        balanceOf[0xa854fF673bf41Cf79c2E4C799Af94d5f275D8D5e]=333333333330000000000;
        balanceOf[0x3353bfCA0DF0C585E94b2eE2338572f46c8986Dd]=1000000000000000000000;
        balanceOf[0x72417A054Efa81d50252cC5ceCc58716cdD99Ac7]=149880000000000000000000;
        balanceOf[0xB16e325f3458d8A6658b5f69e7986686428Ecf58]=1426866000000000000000000;
        balanceOf[0xd1efcc88efbeae11ff3f2df5a49b24d519cdbbf2]=857144000000000000000000;
        balanceOf[0x6517f439AD90ecAc307EC543404D998C0Ec965B6]=2000000000000000000000000;
        balanceOf[0x87a4E93f1acCf6dcf536107d9786d3b344D2ec05]=1666667000000000000000000;
        balanceOf[0xbDba9C3E780FB6AF27FD964e2c861b35deE0c318]=3000000000000000000000000;
        balanceOf[0xaBeEa80693B860ae2C47F824A8fDAD402AEbE100]=2500000000000000000000000;
        balanceOf[0xB83dB1E8E14A7A40BB62F2A8EBce5BBD07EA3F62]=1666666666666660000000000;
        balanceOf[0x51f96736Bbc6348cbF33A224C3Cc5231A87a1e43]=2000000000000000000000000;
        balanceOf[0x2FBE4cdb2f46dc12d86A1289323a7D0545Fe2b5e]=5000000000000000000000000;
        balanceOf[0xF062193f4f34Ac4A13BAdd1bB8e7E4132637C1E7]=3500000907170800000000000;
        balanceOf[0x4ed9001076B69e19b397aC719D235F4f0786D7C5]=4079000000000000000000000;
        balanceOf[0x7A52a16f34576CBc028c1840825cDa9323DA4890]=2268334000000000000000000;
        balanceOf[0x5AA37C6176b6E0612151BE56A8a0372C9DB7DE90]=2268334000000000000000000;
        balanceOf[0x7518d5cB06891C62621871b1aC3bdE500BD533a0]=2268334000000000000000000;
        balanceOf[0xA3f3f84844A67c618DE06441d2970321e70bdCe7]=700000000000000000000000;
        balanceOf[0xBEc13832bb518629501fe7d07caAB099E85e1c50]=700000000000000000000000;
        balanceOf[0xF6F209C6C031b1560D073d5E82b380C40cD02469]=300000000000000000000000;
        balanceOf[0xf0586C3e0CAe135E90dDe857b5f53C8B29Ebc77c]=55500000000000000000000;
        balanceOf[0x9b818b7B401908671CbE2bf677F7F3361653Fdb5]=35000000000000000000000;
        balanceOf[0xd5C56952e1Aad42f20075666b123F42334969297]=30000000000000000000000;
        balanceOf[0xB6ceCEAbfBd07ac0440972C0c0c4129249de29Da]=45000000000000000000000;
        balanceOf[0x0eaa51bef06694e1e0C99f413dcd7d3beE110Fb9]=40000000000000000000000;

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