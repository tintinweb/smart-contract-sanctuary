/**
 *Submitted for verification at polygonscan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1; 

interface ERC20 {
    function balanceOf(address _tokenOwner) external view returns (uint balance);
    function transfer(address _to, uint _tokens) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _contract, address _spender) external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract IdrissMatches {
    uint public countAdding = 0;
    uint public countDeleting = 0;
    uint public price = 0;
    uint public noPriceIncrease = 1;
    uint public minimumAdding = 1;
    uint public creationTime = block.timestamp;
    address public owner = msg.sender;
    mapping(string => string) public Idriss;
    mapping(string => address) public Payments;
    mapping(string => uint) public payDates;
    string[] public mapKeys;

    constructor () {
        Idriss["da32c202731b62069ce5c109666ff3b8d4100a03ade4a60ec22278b15a3ef10f"] = "0xcC428D15930F1d3752672B2A8AB7a9b1f2085BC8";
        Idriss["1293a4a4a05d6bd3dae801a9cbb0bff8dca1bd4e186e0e4908e4986ed6003663"] = "0xcC428D15930F1d3752672B2A8AB7a9b1f2085BC8";
        Idriss["d59de202ebf3332de3f612bc37063e653bc009b25fb1e87d9c70c4fd11ca1dca"] = "0xcC428D15930F1d3752672B2A8AB7a9b1f2085BC8";
        Idriss["959bea3c71afaa28086de7d8f96c348b436c1c1952f54709340b90fe3ba826db"] = "0xcC428D15930F1d3752672B2A8AB7a9b1f2085BC8";
        Idriss["8b95b4d853f7fd87d0cd07f16b39423a15b9c563d47d4e4a5057f6f837130a95"] = "0xb4fce0bcC67fc18B4Ee27680de152733B9e75405";
        Idriss["204a4d863379c86ea77d56cf2e69cb441d8a37334cf34da3f82600fe4e40f555"] = "0xe75bf5A0aA5BF8891b4b68cBdA2e1C12DF4F52b2";
        Idriss["aa3ee79db3717a9adf11af70242264ea7aa4139d3f7da60414dcb895b88066f7"] = "0xcCE9A28b570946123f392Cf1DbfA6D2D5e636a1f";
        Idriss["573a34c48ab750ead0cb61910f86a39a6a98480f39ca2d6c2d399cd89da5191a"] = "0xe15B5F956C64D40A0Ac8D7f16903f3D3A1747D07";
        Idriss["885b76843b50705a1139dbf9f44c82d982db3803fad5bfe9897b05229624d08f"] = "0xc398aCfDc423D293Ff8BAc73c02331609270BCe7";
        Idriss["3d9efb142d70830ad0b17e8c98e754192fffa1287e509acb9a8343a769735ee9"] = "0xe75bf5A0aA5BF8891b4b68cBdA2e1C12DF4F52b2";
        Idriss["51b6ca0e36aa976c79ac6ee300f0440785a1db0a20f33c5dc23cdd6392a9f697"] = "0x150428f0ed090E304d90C343e5eFE7d36213861F";
        Idriss["812a38ef2fad8cb6230282850de59f77e4c97e92ad844a53b28e6f729c573e8d"] = "0x553904536d94789adbb94a2553f5d80fd04b63a2";
        Idriss["046a9694ed9eec9d76c03c505e389a6bb841db899f686901d6efe1a9dbc1fe22"] = "0xa8293Dd8eb52564a35b8357a539146321b934153";
        Idriss["051d4e52e556504febb9fd3c1b53910484ac8296b3e791ad353945ffcaf94232"] = "0xd04Bf1c800f5a7fB380dE6871D0dceA421d57c64";
        Idriss["45e76549eb7a3e2f76bbf95da3224b8e2565d531fb71227d1546044c2338c9b2"] = "0x99244BB065254c906766ADC8d710221e97e65909";
        Idriss["b7b471358640d5850c7a8ddf059fd747df2695bfe9499c2971410a2b67aad9bc"] = "0xe75bf5A0aA5BF8891b4b68cBdA2e1C12DF4F52b2";
        Idriss["ee150c214933b8622733219ede7ba98f4bf10cfeaf63fb4107463f1af3f5dea7"] = "0x99244BB065254c906766ADC8d710221e97e65909";
        Idriss["39a6b6b68c5146356c09b466d9f4c955c4f8dac7e04b29d161171a0f936d916b"] = "0x80e7ed83354833aa7b87988f7e0426cffe238a83";
        Idriss["2924821f327572a211ecf7ce16a79942ddcd4e6d6d40649d99258ca70ce53f6c"] = "0x4dD0D2b69ef1208F9AEbd10Ad53665B420D15e3f";
        Idriss["defc5ff79c36993002e688f8bf6c9a04e217e10b2c4ce7f72a4800b8a97b88c8"] = "0x4a3755eB99ae8b22AaFB8f16F0C51CF68Eb60b85";
        Idriss["334edfd031f3a913e9f6a0be5e7a49e8856ab570e3a52fa8e4cc8af396d58c12"] = "0x6A2D89DF075Af4082dFcca5c9e32EDD2cB95028B";
        Idriss["8c7cb92e05af9c84b4e6e4568bfb607134f4d45cdd4521a35c683f45fea97450"] = "0xd755FaF120FcD18f00aD909375BabdE781834E39";
        Idriss["b7df664d9b8c53780b4e5536cec24d4bcf643b2233ce9c9cb277616e8ba68427"] = "0x1e8b7dea2b3fee688a7b693c4713021dfa3ddf08";
        Idriss["c2d3bdbeff8576abd62045f5ed641265bf06c11b1ee8d14da2137a74ef1858ea"] = "0xA704849D976CA38215A9C1298B2DC4767dB8D03E";
        Idriss["e26aef56d385647f9daf20a57ed3aa18362777bf2f0e30ca7a33a9db4389163c"] = "0xC30d0c3479A29df8Ca869031bede41bF83aFE642";
        Idriss["c73ee79e2b62f323dfecf0c6bf9df5498e8575b349dd55b2e6fe0b0be7549ad4"] = "0x74667801993b457B8ccF19d03bbBaA52b7ffF43B";
        Idriss["3018979beff2560475841a45d41b35cdd9e62c196882f0baa82f8d32830ff708"] = "0x0AF8C8f1045Be77272A09D2513a56a3d4002de6e";
        Idriss["cd390da09c2d331f0ab5e2936bc39400951951b6253c6ad68d64858603299d7e"] = "2nPxiumL1dbMAxrxSLdoWLSGHSjaD12ohyNRw5Rym7im";
        Idriss["9d23b3de5bc76e512b40bb2a7f23ccdd0d6a4c2941836164f97f53fb2bf8d0ea"] = "1575DFtPUsM11gzXchS6f7rbaJYKJA5h5z";
        Idriss["3393492c8ca05ed35fa60057e2ebf16251e2d453a0a9a2dd087d471eb76b8ffb"] = "8soQsYfQCngqJ5gLpWSuuzDUo1YLg53mU6GBF5RBizNn";
        Idriss["c1220fcbbf5dc6cf2abed083b5dfe62dbd923aa63cb7d91fa33d467bba347dca"] = "8soQsYfQCngqJ5gLpWSuuzDUo1YLg53mU6GBF5RBizNn";
        Idriss["548898e0cc89dd5ce195807a987f29931a6b1aad713e216ec2ebb3413cf002f2"] = "GT2Cxwi6jf6H7g3qymapq3WDQPzmH5yJUa31AfDCh1uT";
        Idriss["e3486708aa8e6eeb7f435f792b7f821e69a02a471b74d640f57170a83eda2c39"] = "7D4tirn9UY3E4BxbGsePRiMwSkJv9aWm4MusPG8FeoAC";
        Idriss["41a0f408b8551ef32b04066f972a1418d47686870d2f52c066cf1d518637772a"] = "EXeRYLa7NqLTTc5LpqN16Gma1s6HRqJ5KU";
        Idriss["bd6fb52c144a8ebaeff2c377fc000b191ba18a713a453dffe5bb320b25a7aeff"] = "EQcqG34JfukHqkAZNcDxQdgGNuhfACyd9p";
        Idriss["56146e2942a212dfc1f36386e3cf2f072b5dc0716e51ab0d988c843179dc2ed0"] = "EQcqG34JfukHqkAZNcDxQdgGNuhfACyd9p";
        Idriss["98ba55238b876520f5b2d554024aeede64afd0723624d1481c20fd610a515954"] = "0xd98f4A547dF3006960b05EF7c976064F79001676";
        Idriss["ece7b7b136c11c06026bdd66953230d7273781f9072a0a0f2af965421db337e5"] = "0xfd2409c49f6c2c73d7894Ef2eD75B6C7fEAF480d";
        Idriss["8f0b3bcef9b756961be2bbee3353a30d7ef2cd6dc98731528eb62a27693437b7"] = "0xcCE9A28b570946123f392Cf1DbfA6D2D5e636a1f";
        Idriss["abd7f872a15868ae81a656ca3a9ffe71c68122739e580e56e749b24840725424"] = "1575DFtPUsM11gzXchS6f7rbaJYKJA5h5z";
        Idriss["9d68d1ed251d4364392752ede65e0c2ab513da8701e180d17473a05bd6d65c73"] = "0xfd2409c49f6c2c73d7894Ef2eD75B6C7fEAF480d";
        Idriss["2295df7a711cd03ae1f8b92eb2ad794a5744d31806427d7b75b5a33256ce8cb9"] = "0xd98f4A547dF3006960b05EF7c976064F79001676";
        Idriss["627b765aec8cc902a9d80a806ca5b86c9876c92a4c5492171a906853aa2345c2"] = "0x80e7ed83354833aa7b87988f7e0426cffe238a83";
        Idriss["ba4dc433f8c857ee6a2a69f28805b530939b9a0574ef07f9338d9ca14e6b83d7"] = "0xC30d0c3479A29df8Ca869031bede41bF83aFE642";
        Idriss["2894c2c6d7316257f6dadaeb4814aefee0027fad5461f870365c107a78620ce1"] = "0x1e8b7dea2b3fee688a7b693c4713021dfa3ddf08";
        Idriss["5b3ed73368a14153d5b155536bca77a2edaa0f78aa1b01e6ea9a3f010f0be15d"] = "0xd755FaF120FcD18f00aD909375BabdE781834E39";
        Idriss["8b6cc552611f2bd2290c1e327178471f825726a76b49f08798c77d4282b94485"] = "0x99244BB065254c906766ADC8d710221e97e65909";
        Idriss["58f0f8703a54ca664f1d49ea811bb547ea9b00ee5208654933fc164062171835"] = "0x99244BB065254c906766ADC8d710221e97e65909";
        Idriss["5a4bea6d87f887c9beefb7933a6d12b19c2adf64d70adb07c06db3b5fede0121"] = "0x4dD0D2b69ef1208F9AEbd10Ad53665B420D15e3f";
        Idriss["bebf63d3194a4168720ba6050afa2e58021c308d3cb224f77811dcecd47ca32b"] = "0x74667801993b457B8ccF19d03bbBaA52b7ffF43B";
        Idriss["16f0104e9a838777e362dd569dc9823c89ccc630dcc2f1eb24dc08358ffadf63"] = "0x0AF8C8f1045Be77272A09D2513a56a3d4002de6e";
        Idriss["a37f3ad912412260c3681f5d3d33f1a2c78650d01f1928a93d8b0616b7fde56a"] = "0xcC428D15930F1d3752672B2A8AB7a9b1f2085BC8";
        Idriss["52f231299e26d382f7dd69766638ac87d5d2e76e515a698af62d9861f12649f3"] = "EXeRYLa7NqLTTc5LpqN16Gma1s6HRqJ5KU";
        Idriss["b90fb061faaffc66368439efb68924daf5b442dbe0bba42019df05b428256f7f"] = "EXeRYLa7NqLTTc5LpqN16Gma1s6HRqJ5KU";
        Idriss["196902967005926bd7cd94e218ad77774ce0ae0cc4d872cc370752cf3a7ecc1e"] = "0xcC428D15930F1d3752672B2A8AB7a9b1f2085BC8";
        Idriss["7013bf9135622a23d99e9cf894e75d8d8e365448999cf002759ce8ffc89aa344"] = "GT2Cxwi6jf6H7g3qymapq3WDQPzmH5yJUa31AfDCh1uT";
        Idriss["71971c1ef42ca379031836cfc70c4b643b951c9515e9788b65121b514efa1b59"] = "0xc398aCfDc423D293Ff8BAc73c02331609270BCe7";
        Idriss["77b0de1f96855bec8517c80f04bfa11ec1074c8e946a2e942e060486176f7f56"] = "0x6A2D89DF075Af4082dFcca5c9e32EDD2cB95028B";
        Idriss["47616a5d41a3a90f665d7f68edca6f4ff6541a3a5a669f5b1dd5dd1ab6a88e17"] = "0x599C3984C1CC557B4eF5740EFf305b34761679ae";
        Idriss["ffe583d06aed6e18af8a77a77f1a0d254a6421d56e8f50dd086a7351f915c888"] = "0x599C3984C1CC557B4eF5740EFf305b34761679ae";
        Idriss["132dbca11b85aea78be640a2e80e045a43ac61b382713cd231371e55b72f5744"] = "0x4a3755eB99ae8b22AaFB8f16F0C51CF68Eb60b85";
        Idriss["f922ae3c5540021b2ae1666d44c60cc5b7588ca09ee6340e48b2d74afdbce5b9"] = "0x4Fdd2d00df223d085C9EC5116dDbBefDf23ef5cC";
        Idriss["101b6566414c5e0ae49898e643138aa6a332df9e7c728f201514298b291dca86"] = "0x6a0bCffDc0ea59F10B8a9721Ca1F569935D95D05";
        Idriss["56ea16efeaa40a32d0920c33078d16544da2955fce51b4fbf70cae90a675f5f9"] = "0x5EdEb2B0E45ff5549235148643Ca059a679EB490";
        Idriss["b77605c7164957ffe6768f5c6281a02be71893992ab162c5c023d4604ba3e3ca"] = "0x4a3755eB99ae8b22AaFB8f16F0C51CF68Eb60b85";
        }
    
    event Increment(uint value);
    
    function setPrice(uint newPrice) external {
        require(msg.sender == owner, 'Only creator can set price');
        require(block.timestamp > creationTime + noPriceIncrease || countAdding > minimumAdding, "Too early!");
        price = newPrice;
    }
    
    function withdrawl() external {
        require(msg.sender == owner, 'Only creator can withdrawl');
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function withdrawTokens(address tokenContract) external {
        require(msg.sender == owner, 'Only creator can withdrawl');
        ERC20 tc = ERC20(tokenContract);
        tc.transfer(owner, tc.balanceOf(address(this)));
    }
    
    function increment() private {
        countAdding += 1;
        emit Increment(countAdding);
    }
    
    function decrement() private{
        countDeleting += 1;
    }
    
    
    function addIdriss(string memory hash, string memory id) external payable{
        require(keccak256(bytes(Idriss[hash])) == keccak256(bytes("")), 'Binding already created.');
        require(msg.value >= price, 'Not enough money?');
        Idriss[hash] = id;
        Payments[hash] = msg.sender;
        payDates[hash] = block.timestamp;
        mapKeys.push(hash);
        increment();
    }
    
    function addIdrissToken(string memory hash, string memory id, address token, uint amount) external payable{
        require(keccak256(bytes(Idriss[hash])) == keccak256(bytes("")), 'Binding already created.');
        require(msg.value >= price, 'Not enough money?');
        ERC20 paymentTc = ERC20(token);
        require(paymentTc.allowance(msg.sender, address(this)) >= amount,"Insuficient Allowance");
        require(paymentTc.transferFrom(msg.sender, address(this), amount),"transfer Failed");
        Idriss[hash] = id;
        Payments[hash] = msg.sender;
        payDates[hash] = block.timestamp;
        mapKeys.push(hash);
        increment();
    }
    
    function deleteIdriss(string memory hash) external payable {
        require(keccak256(bytes(Idriss[hash])) != keccak256(bytes("")), 'Binding does not exist.');
        delete Idriss[hash];
        delete Payments[hash];
        decrement();
    }
}