//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

struct User {
    string id;
    uint256 share;
}

contract Token {
    string public constant name = "Connect2Evolve";
    string public constant symbol = "CO2E";
    uint8 public constant decimals = 12;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(string => uint256) private allocations;
    mapping(string => address) private accounts;

    User[] private _users;
    uint256 private _lastSolartainerReportValue;
    uint256 private _totalSupply = 1000000;
    address private _owner;

    using SafeMath for uint256;

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert("Only the contract owner can perform this operation");
        }
        _;
    }

    constructor() {
        _owner = msg.sender;
        balances[msg.sender] = _totalSupply.mul(10**decimals);
        _lastSolartainerReportValue = 0;
        fillData();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.mul(10**decimals);
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function setAccount(string memory userId, address account) public onlyOwner {
        accounts[userId] = account;
    }

    function getAccount(string memory userId) public view onlyOwner returns (address) {
        return accounts[userId];
    }

    function transfer(address receiver, uint256 numTokens) public onlyOwner {
        require(numTokens <= balances[msg.sender], "balance should be greater than the token to transfer");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
    }

    function approve(address delegate, uint256 numTokens) public onlyOwner {
        allowed[_owner][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function allocation(string memory userId) public view returns (uint256) {
        return allocations[userId];
    }

    function distribute(uint256 solartainerReportValue) public onlyOwner {
        require(_lastSolartainerReportValue <= solartainerReportValue, "report value should be greater than previous");
        uint256 kwhToDistribute = solartainerReportValue.sub(_lastSolartainerReportValue);

        for (uint256 index = 0; index < _users.length; index++) {
            User memory user = _users[index];
            uint256 quantity = (kwhToDistribute.mul(user.share)).div(10**decimals);
            allocations[user.id] = allocations[user.id].add(quantity);
        }
        _lastSolartainerReportValue = solartainerReportValue;
    }

    function fillData() private {
        _users.push(User("map100erzf2hk6s6xcq30qtfc6znrh7l4f7v59w9md", 99000000));
        _users.push(User("map104wmvan7rf3k42lg7z60uxdccmerg63zzc6lf4", 33000000));
        _users.push(User("map10cfd3sq7qscms2vd7dfk2u6tntafn2g5qk7xhn", 530000000));
        _users.push(User("map10j63760gq70dwmfl04yaqmv3zcvmsxcalezhjt", 83000000));
        _users.push(User("map10jycpv4hl2p8yugha66hast2v5pkd8uyh68vup", 331000000));
        _users.push(User("map10k9647jdzc4ryv2awqh7uwfuwqk9yxk90pawsw", 165000000));
        _users.push(User("map10lmwp34drdgmdkg3yk6pzvx4enl3l8mkp6a3fv", 881000000));
        _users.push(User("map10sv5lpkp3ywqqk5plt44fjympequmr3r3uqqy3", 66000000));
        _users.push(User("map10x7pve3h7x7aqvcrqyvza042caq39frvphtyj6", 265000000));
        _users.push(User("map10zk49zdpzss5dmakfc0sys62xt8j64lep5pfp3", 305000000));
        _users.push(User("map123derkqmj40ddg2xfgt2pas74nunh52vh3m674", 331000000));
        _users.push(User("map1290q9kjt58qg4jk5zfu5g0k8eh3d2ugkjs5yrm", 94000000));
        _users.push(User("map12cdw4p8xv90f0d06tkd0ugdf7y4eapg5ldn0ry", 265000000));
        _users.push(User("map12cv79kg6e2vg6ykvyez7xa36glymc46eln7jjw", 153000000));
        _users.push(User("map12dcn8ylhawkg4cq9n57c049vewcazef73mpdra", 61000000));
        _users.push(User("map12u0jzmnfy7vs7setq54knxwuaelqk4py57hp2k", 33000000));
        _users.push(User("map12udls8fwaqjf5r99vrl6d0709y9gne7uhw3593", 331000000));
        _users.push(User("map12yq6rhtleevjrkd0h9lsmvca9a6zq2khfulcdy", 165000000));
        _users.push(User("map137gv76ccy7nlyyqvfpx4sde64fch2vak7hqgg6", 165000000));
        _users.push(User("map13jnu82a2mdt7urdg4ytyncf4cwxh6zvxz35flj", 139000000));
        _users.push(User("map13kqp3q90wv4hs9mz2c3zq9amjcvq4qr2tsmdc6", 40000000));
        _users.push(User("map13phchqqmdmje99n8fganxzevumwt50sklkl7e8", 33000000));
        _users.push(User("map13wxwlk6eacdw0vqxsd3dx0al9z4scjdqkgaf37", 66000000));
        _users.push(User("map1446pscg0gg7mn56jmhky64jxercv6phamet6z8", 165000000));
        _users.push(User("map144vqpmn8x6wkjp4f9r0pfn322y88xdr7md9p2y", 55000000));
        _users.push(User("map14jcpv798s4565fnphqgp8z8ea39chl2l5g0w5d", 165000000));
        _users.push(User("map14jersy96wuwucxr70erxcjnnxdkeyfx9gesaaw", 331000000));
        _users.push(User("map14k2f9sfc3uqaa9jr7cdel6l0hqr5ujha4854gx", 165000000));
        _users.push(User("map14tpl26g6sgy9uln5xq8cesqx8jla2jlq06v22l", 33000000));
        _users.push(User("map14vmckq7g5alf5hex4j2ct686vq204qy95g6wet", 331000000));
        _users.push(User("map15d8he8yg08xxm2g0mj2fwdj9sfq5ra2943ecue", 662000000));
        _users.push(User("map15gr6mey5pc8pmc80x0ae3m8m3g8f2x6fchqxff", 99000000));
        _users.push(User("map15md5ps6ealkp4cjn6lrhjc2s4y9sv35a895sma", 307000000));
        _users.push(User("map15pf99km55h4fk3fjppt6tpp2uvfefr6ckr7m4s", 108000000));
        _users.push(User("map15psuyjyczzaltywpue4k6gn0kvnjtamkngm790", 993000000));
        _users.push(User("map15pv0jmjrwzhvtqhk27tp6axlnj7kv23v8uem0y", 333000000));
        _users.push(User("map15qpsrzesjnyflmyhwkdpp5d9d8gwtk6g2g2jme", 199000000));
        _users.push(User("map15y2evk6njv5x8t8yt9d9arwks8lkmcdu7hkghk", 33000000));
        _users.push(User("map166zsys6cj898k7dkyctyr98x9tcm4rxrj2wgdj", 331000000));
        _users.push(User("map16dh78ama6vvacrsgxjckkcdp3v7mx5gcyfsfey", 165000000));
        _users.push(User("map16frdp0hekyc4uhff8ygqugw2ewg5twvqzhmcs7", 331000000));
        _users.push(User("map16hh4rxy20vgvuywqvrms653f9evgwkv85tq43m", 331000000));
        _users.push(User("map16kh9z7cavkh5juu24a3g7uak66dseku6llhta6", 83000000));
        _users.push(User("map16qt6g7dahufvu4ym72hx5yhu2unahafma65c87", 66000000));
        _users.push(User("map16qupwac8datadpf8pxlg0f9jrhncz374qhu3j4", 331000000));
        _users.push(User("map16s6plfk3nz5wfhpy2rvadvran6q78a8dkhtyn5", 99000000));
        _users.push(User("map170457usx5yt9rchc8758gkhsq80kqt85qfwxys", 33000000));
        _users.push(User("map173w2u3en6j3a9uvayzkm2e07pk64n9rh9tgfqv", 397174000000));
        _users.push(User("map175qves647536n20pvyppc32k93k0k5sx667849", 40000000));
        _users.push(User("map17djxdtmfn4enyyn78cxvd2vwxx357cufdrde68", 33000000));
        _users.push(User("map17l2l2h6yx4gk7scnlqs4wk4gxttq4v5nar6p6e", 827000000));
        _users.push(User("map17m6llnmj57gqlx36lzmgnuuk2guctpma4ked79", 165000000));
        _users.push(User("map17na75wme3e63z6v7n6r9kjnnu86thw0ryrua3d", 165000000));
        _users.push(User("map17nnq0sxr9cs28r0qqlutkqn3kacfmlz7aatmpf", 331000000));
        _users.push(User("map17sqytx2vmqrtrpnyyury25jkazu4zw46fun4za", 232000000));
        _users.push(User("map17y44ylht47dp8kuaexwdr4dsl3tnfehg3d89m4", 331000000));
        _users.push(User("map1846rurx4l080rwkwtf2q7mqvcf2u4mlfkswn7h", 66000000));
        _users.push(User("map188pc04s0rwkpkvrkujymjtyw2hpe2wkl6dnucx", 33000000));
        _users.push(User("map189gdttye7hczz8h8kmyc6pu6gmf8aty99mhrvl", 66000000));
        _users.push(User("map18anshdys39022v4sm8ftrn46nm7qtuanglq2ac", 165000000));
        _users.push(User("map18c0wen85q8flgj2slx4c3j2serly2dfttd7gwl", 331000000));
        _users.push(User("map18tsezdpl7rl0tka8vky97dnfrd8s09xwcm53xy", 66000000));
        _users.push(User("map18vr4z4eln9l5hnrj8z03yrtsqxxcmp40ns338h", 496000000));
        _users.push(User("map18xam97c9uqs2wt6p672gf3mvzphuv9tlsp3xmu", 165000000));
        _users.push(User("map196v0nwhs33vtl84ak9a7ztd0c7c3h2qys3dw8h", 66000000));
        _users.push(User("map19clp608wmv7l8xv8h5w7x3w0384crtxgvkq5vx", 1688000000));
        _users.push(User("map19fyfdetwwpau4rs8lykre7d8ufkrae8944kf48", 33000000));
        _users.push(User("map19hfzzuuyqzsqqxqywauskw7q27w3rcqf6rcj0n", 182000000));
        _users.push(User("map19jzvd8q3dhskymmfynhnj66k2kygzezxpc2eq3", 165000000));
        _users.push(User("map19mtw54yjslnm3a40nz7kjw237wnpkzpu3v0vad", 33000000));
        _users.push(User("map19sevagtx556ygmfgsltn8m7h5w8cmym6fqf6wl", 66000000));
        _users.push(User("map19vm5tpc58az9u2duj6u2h2gw5jg8dakl0synjm", 50000000));
        _users.push(User("map19ycpw092e36wmq58npzt6s90xr5zfcrjj93v0j", 662000000));
        _users.push(User("map19yka8f2cj9e6jq3qhxrmsf05yqy594ujng5vem", 83000000));
        _users.push(User("map19zhsu2kfl7ts0akamgmwv6vzmdrq4kc64mjv2c", 70000000));
        _users.push(User("map19zmfzzuf2r8269xtwnq43jkza9vmrhrp9m9hau", 728000000));
        _users.push(User("map1a3n6sstgn6lfqusah646749jkce7gens30y645", 602000000));
        _users.push(User("map1a3yk5g9mdlnds6wh5kaaun9yssx7jmgn6aqpr0", 3651000000));
        _users.push(User("map1a5j6xl30uk3u6eap5hm6npzrrtcma6e7zye7er", 662000000));
        _users.push(User("map1a6vn77cda8naz234kxcnt4upmeya4y26d2dz6d", 331000000));
        _users.push(User("map1aag8q2duu2djmdsvjyr6zd87pslyusd2m9za9e", 662000000));
        _users.push(User("map1aeld2u4tcxqdvlauygwjg9fryrtvdvzdhr2a8u", 165000000));
        _users.push(User("map1ag9dr6k6s3jw3rfjdu0mkrdkcatvr8da8x5ma7", 132000000));
        _users.push(User("map1c07erff875qdy5e6gkaetvzhlh97ytpcx04eey", 66000000));
        _users.push(User("map1c5x79m53f8kqqxqll5h936y3f27kd0742v85sk", 1721000000));
        _users.push(User("map1camx5epjya6z2r5dwj88wqt3ffr3txup8sq9zm", 165000000));
        _users.push(User("map1cfgzhs0kgmtppgrya88xf7wq2qvphekj80a32f", 331000000));
        _users.push(User("map1cn9npszs3ar3r724c0dwg2hh5g6n88g5k4jp2l", 662000000));
        _users.push(User("map1csuaqjcfu8skkc8q3yahc3ky9934ulvz9an5l9", 33000000));
        _users.push(User("map1ctuynae3rm8423ujcnm27q6w4263v0gd5wzm0z", 182000000));
        _users.push(User("map1czh8qg384v850r6xduhytezr5mspca9zj5rzew", 33000000));
        _users.push(User("map1d3y02g83w9ux52r67sgn7a26j2e7p5cs654agr", 66000000));
        _users.push(User("map1d98g7te9w3wltqu90udqhnascc8rdyerf2826a", 331000000));
        _users.push(User("map1damrpn6p06lxyaedqx2vyrdrr6xdzzu4a4sqtp", 66000000));
        _users.push(User("map1dej5tkek2azulfz3zsgy0d44jms370eke8zwsh", 66000000));
        _users.push(User("map1dgem3c50q7h0d9xjff49eznmzyyh26vvrgp23g", 33000000));
        _users.push(User("map1dp0uya5vwvshxpnjecge0z2tvpvhm98tuw6752", 66000000));
        _users.push(User("map1dq34pehhj6r6u3kuq2xs9c9vj3fyyvd7p8qx6w", 165000000));
        _users.push(User("map1drxgjyr8s5frtkvc23ng5ep68hsknzml4kwzhj", 165000000));
        _users.push(User("map1dur2fr43p93ukm8yd43rpxcxf27r8wvyh80kud", 331000000));
        _users.push(User("map1dv9w684pa2nwv0xrjjqwn087cazldyxadrqh8l", 61000000));
        _users.push(User("map1e0szlv78e256m8fk5cxj7nhc2y2wst6ls6qs99", 165000000));
        _users.push(User("map1e8k9pft46pk9y34ajldsfl7mgrk8775fp9cgkd", 83000000));
        _users.push(User("map1eep308zap8pm3k50pze5dkx97qfzr2p5pkmmzs", 66000000));
        _users.push(User("map1eewnlu2s80carg4ehwmetakpsrx02xc04gp3s6", 530000000));
        _users.push(User("map1ej5apw45v3a55qaradsjyxslq4ej5rshg8sxx0", 31000000));
        _users.push(User("map1ejf3k0d8ruafsjp52hfn0qk78n359vd60256z4", 827000000));
        _users.push(User("map1ew5955n95mye5p84900j84whdx9adagnzft4ux", 33000000));
        _users.push(User("map1eyc0st0e50vu5y8mfkyv5z2txgqezhx6e9ln76", 33000000));
        _users.push(User("map1f6vlp04wpg9nu5z2swl9xkuvac0d68ra734cm6", 165000000));
        _users.push(User("map1f9ungn7hjt945m69eypc9n659p8jgv5r5fzp2a", 61000000));
        _users.push(User("map1ftcfejnn5sv7wqg36mtxxum450w24zpyxq7mgg", 500000000));
        _users.push(User("map1fw92jng3xjd985tn7tka3704x5mf9nemhymc9z", 33000000));
        _users.push(User("map1fwn4ww7cptg6a0vpcd69xxa998wc4uktv8uzkc", 662000000));
        _users.push(User("map1g5un59n40c3uf7ptpjz7r2c0s0jhvzlxsuanyp", 138000000));
        _users.push(User("map1gaj4jvjj8m6354fj8v5ex4rnfl9lempjncgjlr", 165000000));
        _users.push(User("map1gh5ldzk64s052xmxmmu854afqmgesygq3tzg0c", 83000000));
        _users.push(User("map1glj2yep02hjc5eael7r47fp84grf2cfh4xr0rw", 66000000));
        _users.push(User("map1gp4rxy24jkvxrk40tprll7cnksfe3uyrx2dm7k", 331000000));
        _users.push(User("map1grzup32recva5nt9c9z2jgysfwy36lre0nzafy", 1655000000));
        _users.push(User("map1gx2zj7a4kqjcqq9t6va4zjun4gn2z30wmlqht0", 165000000));
        _users.push(User("map1gxc8p3gfc4k8nq73v4kc6wl8cdswl8ethgy9pp", 165000000));
        _users.push(User("map1h4kkhtez79ddypa254jq0h8x8yqncedtj3fxuq", 1679000000));
        _users.push(User("map1he3xhkwkkkmmvflkxwv39mmh5gykkrh5hh2u27", 331000000));
        _users.push(User("map1hhl85dscdrh5cu5lg9t8scj450lcej09wgrjjn", 99000000));
        _users.push(User("map1hlm5azxpwa790l4ge3jzppglps95r7p5z6jxhz", 165000000));
        _users.push(User("map1hnmuuwpvenvjnpy6rnfw98gqj6ywgacf96kspd", 33000000));
        _users.push(User("map1hs9yqfdk6rn4hxs6kfzdhf0xhna2qcymqrg7m4", 1133000000));
        _users.push(User("map1hz4gzcyujtq2nw0zg59rv76gtz34kklm3nn49s", 165000000));
        _users.push(User("map1j0s7mdw2pc24z8h0k4yqywju6f2nna0guahlhm", 31000000));
        _users.push(User("map1jgjhg369tfscp65gue2x6959alxrj30j39t0p9", 165000000));
        _users.push(User("map1jnr0k360mm25wj99m08jfjlan768ypmez9zsc0", 165000000));
        _users.push(User("map1jwursryn3mnaxcnka40dkzy5hkwtcgtdnukwpe", 53000000));
        _users.push(User("map1jzvk5mxfx7r4lfngqr2p7l263wzqmf8hu5m2p4", 165000000));
        _users.push(User("map1k86p3m4j8cffxdl6vccyq9nha65jh5aetpnlqu", 530000000));
        _users.push(User("map1k90u3kc5gredu7lpts93yyclp4ac5tssrtrth2", 165000000));
        _users.push(User("map1kprkzscu5kmq94ldg9k7s0ck83lcmvrx88gwcy", 33000000));
        _users.push(User("map1kq6w4mn8lyx3rkfvdpxgypqlqm86gatl67hhlp", 99000000));
        _users.push(User("map1krdy0pwa8lnn6wa5w886s3zfjlf7eky5acxj7z", 496000000));
        _users.push(User("map1kvzxsfps8plvw57v7ug9tfgum9qh00fcnkxepa", 500000000));
        _users.push(User("map1kw7rm265ag6yrwt8defgy88sqhnzdcf9xsacfv", 33000000));
        _users.push(User("map1kxecjuu8u2wlwhwpkhfr6uvzcv5l5s82ye2rf7", 66000000));
        _users.push(User("map1l7g7w34vgp0xhkacyzj363wgpz9cfejrsh70jt", 331000000));
        _users.push(User("map1l9ckvdwl3ycvsqy66s6us4kf0jv9q447yaf6mc", 662000000));
        _users.push(User("map1lglx6fvrqdm0gv2049da8ep2rz7syk9gpdmwu3", 1424000000));
        _users.push(User("map1lleswn88j3w3zfp2kgk6djnzjsynhgjut7j06r", 66000000));
        _users.push(User("map1lp0ex0gpe5yvne6nsh3dkf6h4yymsh4pgl4cf4", 331000000));
        _users.push(User("map1lp75sldj60pegeutthcaxkl6rqdt8xpmyvgf4e", 75000000));
        _users.push(User("map1lqkf2kayw8l6rllddzv0krx33qzggucg3avle4", 63000000));
        _users.push(User("map1lznhjrzvc42sym9mhuxtu803k8w9m2d2rc2rvl", 66000000));
        _users.push(User("map1m2zf50fplh34usavwg7akzn7w23cgpmcp0mpks", 36000000));
        _users.push(User("map1m8wgkvt8kzmy3r3vd4luuuyu6m5yvdpwupwc9m", 99000000));
        _users.push(User("map1maj3mtxky94yp67mkfhm2htk330djpwuwf5873", 165000000));
        _users.push(User("map1mau7mtuymc9klvsraxnzq800g25gzet2fr2smf", 728000000));
        _users.push(User("map1mfz36srraylfehkngq9qsevrutmnk03gtfymv7", 1820000000));
        _users.push(User("map1mm6z7r3edx0z4e5jtp7vrh3ztr20zy2erp9vvf", 331000000));
        _users.push(User("map1mshdayk3yyrx74avfvp8nydg3qanp5ct5upv5r", 153000000));
        _users.push(User("map1n43a2wppsae7gnu5r6nx73fntmwgq63pwnjpt5", 331000000));
        _users.push(User("map1n5xm09d0rprppvmr720ahhpkp49tuz52gzaph6", 155000000));
        _users.push(User("map1n8jy5wnag0398c0elgjht6see7eh44lv02kmhq", 116000000));
        _users.push(User("map1na603typrknr7xuejcs5mnynwxafju9zf84jd4", 1655000000));
        _users.push(User("map1ncs2jmwucraqnse4f3fjexhw8f35aaye9t6hkn", 83000000));
        _users.push(User("map1ndly60pnh4qln0za0geauau2fkfrtge0l8r26e", 33000000));
        _users.push(User("map1njn2nscydp8l8q2kcx44lqy8hp2snggv63kzkm", 165489000000));
        _users.push(User("map1nkjp5dw0naf05h90sudmx6g9jkg8ax3z2vxy4g", 61000000));
        _users.push(User("map1nnl0zvn9fg8uhtqcfll2hemckjhyjl077s4hfs", 99000000));
        _users.push(User("map1np9y2y04vx0rma5yrn4grk8jq9cu65pwvndsqm", 66000000));
        _users.push(User("map1nt8g269l2e4rkevfjt6kzpxqpuzsx8vcm5k2gc", 320000000));
        _users.push(User("map1nzpqjfu4wgmjvyjczhj6wjrlvhyfje3stys2ev", 165000000));
        _users.push(User("map1p2kuz6txv9k586qsz9xskecc2g6845vuz89g4k", 33000000));
        _users.push(User("map1p340c8u49ke2cpswchxm8rx69v4c604e3aqnv8", 331000000));
        _users.push(User("map1p390m690lycy6ksg84r8kt7v9p8nppg59c7fqc", 496000000));
        _users.push(User("map1pep5yvqhlyakh25addxdtam8hcrs5zlfzlad2n", 157000000));
        _users.push(User("map1pk0fr34rhzzxevgngtd7mj0u0wjnjjlk5rxgag", 35000000));
        _users.push(User("map1png6fl9srh3838t3sa73g2a90gtyrul8ce4702", 198587000000));
        _users.push(User("map1pp3wvza20758qyk82krmyuchar09elcjdhyvlf", 153000000));
        _users.push(User("map1ppj3sx5vxrls446f2v2aj9psdtsuf8m6tcqruz", 33000000));
        _users.push(User("map1q2crd6tdws787gxdrgzvljl0w30ylgm8en9cv3", 331000000));
        _users.push(User("map1q37l449p73z4jc5qzg3ky6ujrsmshzyft4pmpz", 295000000));
        _users.push(User("map1q6zf2cnywhquegrx04ptgh8dn4ss7snrgqujnc", 331000000));
        _users.push(User("map1qcqpzrjcxke078pvmf9ysjfh8x2yd936jajfy0", 149000000));
        _users.push(User("map1qdd74v0y9pxdqml8urmg503dvdtz9nnqe5avh8", 33000000));
        _users.push(User("map1qghn2jpm5dn98v7ldf7fznpn0z5xpqx32j785v", 152000000));
        _users.push(User("map1qjpvew5eesgcaj0vmsc8fkqctmgqxlcennfj34", 662000000));
        _users.push(User("map1qnwm294ft8zyvafgv03u7vp57yf6xyrds2wa3x", 66000000));
        _users.push(User("map1qpzqj9f2du7ffhqlrmgw3a535p43nchv6ucg4s", 99000000));
        _users.push(User("map1qsn90hf0yn4gyjtqt95r9a4xvy2z3x86ks6wye", 33000000));
        _users.push(User("map1qumkdcrz9yzdvhaf3xu8k4zmtht0fvx3nvnqtu", 66000000));
        _users.push(User("map1qur8en0j6ls6y8vfmnh4ta9lg4xw70v6wjg4wm", 827000000));
        _users.push(User("map1qwrm7u5z5t9mhzl34uanf7auwhd82jqrjk0phc", 306000000));
        _users.push(User("map1r6y7wvlzgrem8wmcg6yx6w5lhn565h3r6gen2n", 331000000));
        _users.push(User("map1rhcs4sjgyq5z6lsrdkxx0m2m3vuwd9lvq9sm5w", 165000000));
        _users.push(User("map1rk06wznepr4cqgadaqmf43djdpk2vyfu5l5v7g", 331000000));
        _users.push(User("map1rurhhqmh9fnh5thcwnc4rlymrkehf8tct33uh7", 66000000));
        _users.push(User("map1rwcftw6ha52ter5te2h6jmwd9pe48rqs42jhvc", 83000000));
        _users.push(User("map1s4s9tjytalq4csp78l7fx2cucqs6wuhwhzdxyk", 662000000));
        _users.push(User("map1sc8g2866h37vz3aamqlny0ngrxngmk0p8lqcu6", 99000000));
        _users.push(User("map1scvcvmulx3cmw7h6lkrug0zkh3gvsnaxpdkvsd", 331000000));
        _users.push(User("map1sf46fccgqjm7csa3gzl8ecsj22yk0sd43pwdwy", 149000000));
        _users.push(User("map1sjtfsvz3lkdq2teee9tapc0xrru08xd5rva4ca", 331000000));
        _users.push(User("map1sqk4pyvsyf43p55h2ly007sjql6tdav8damfh3", 137000000));
        _users.push(User("map1ssnc5t42q3mh3c2vnwnzq2ldddjefw7du6rk3s", 265000000));
        _users.push(User("map1t4y7nfzwkgz3y38plvd0caz93hx8pleuswmndt", 66000000));
        _users.push(User("map1te477x3qfeklgz2y2vpp26vc93uadg2cjyttpv", 165000000));
        _users.push(User("map1tfp437gefsgqmnatt70mg4nfdazm7ete8687ts", 165000000));
        _users.push(User("map1tgdfa6cqxzkwfuz0gzv7s7ekzc9dffmq4jjq5t", 165000000));
        _users.push(User("map1tkvex84jq8d3q22qm8t2ge8st0e0ukw0pgen35", 99000000));
        _users.push(User("map1txdygjz3qj05xp0e7dwl6knfp2hspjy8vuezrx", 6032000000));
        _users.push(User("map1u8lepktmgr4g2mlvs4qyu9yy8dfzzfnna5cxkd", 331000000));
        _users.push(User("map1uevwvz8nwpy5wv3p2hmd6fwtkruzf87npp3rcv", 331000000));
        _users.push(User("map1ugzhzs7sxhgdvf2rkjg4wj3k420s62tteasldp", 66000000));
        _users.push(User("map1va4x3fjfjkhhn825ls4rqdk22v09gzmdet3znx", 530000000));
        _users.push(User("map1vd58k5xjjvye9l7qpl04x6pjzzm8s7j2kr5v7d", 66000000));
        _users.push(User("map1vne2n2ssrjzazzx5ewttsaxwxj4d5vwrf4qeqm", 50000000));
        _users.push(User("map1vredum5l73u9vx8zrf6zmwvm62k9vdjdvtrw2r", 2019000000));
        _users.push(User("map1vzxlh4uxnwf9d8c5ylqc4xxpgtj5y84rthsdm7", 66000000));
        _users.push(User("map1w4uklj00zfddyv6tp8gz0rpj2w98pja7nlwe09", 331000000));
        _users.push(User("map1wc09kelejatz2lepqj6p6r8n4qwj6hhkgpu642", 165489000000));
        _users.push(User("map1we4pl4twvpuzp22y7awthpxn4ryt2gayld6ety", 331000000));
        _users.push(User("map1wekd4xr0t7ggj47wsun9nr024ltsnzeyspk0gc", 165000000));
        _users.push(User("map1wf9srz7drs3u8tvr4mx4x4lw3vr6wnesqmn2f7", 662000000));
        _users.push(User("map1wqgz9kkmr7hp0msha9rlmxuqal745570s4mzd9", 331000000));
        _users.push(User("map1wtp53ra0j7jwzd4gzgfml3f930ggjgtayzsst4", 513000000));
        _users.push(User("map1wx7xrvly8d9e3tt0f4jfkujq3hm9evxm5ecvlw", 33000000));
        _users.push(User("map1x7gn5keenhdaaqscy6c97tlqa8297syn4scgcw", 66000000));
        _users.push(User("map1x7rjqntxvfssa2ksp05pu4wptrz70k7gs4frtp", 165000000));
        _users.push(User("map1x8lgf0dt9388eqfcsf8meyf9dmp6a90hprc0vn", 172000000));
        _users.push(User("map1x8qqdsxglsvyesecaqqnn6gjd2swuvp9gwvsaf", 232000000));
        _users.push(User("map1xlazcet3r7g90k8gtj2kddaenzdwsmuq7353cu", 165000000));
        _users.push(User("map1xnu6npuq85r2gvhkddyy6cem9j0hp9umul63n5", 165000000));
        _users.push(User("map1xu66fvsnyykhcw00kmmktme56seg67q6tmadyy", 331000000));
        _users.push(User("map1xv0zpvdppsqxnj3yyn0xtrvwff9kkpuvhqk9kf", 165000000));
        _users.push(User("map1yjaazkvvt97cg527svura6d3gcljvy0cvjd95h", 165000000));
        _users.push(User("map1yv7auhm2h23f2lpdgj98yacddsuf9urnfr95f3", 165000000));
        _users.push(User("map1z8dalshjn9de0qcqggy7du9jhrn832ur9vtcav", 66000000));
        _users.push(User("map1zctav26nq3kje7pz4dqspkjjdlhwjhlqungaz7", 331000000));
        _users.push(User("map1zgrpvwel7hne8n55x20ptnnwjmjqyazz28uk06", 165000000));
        _users.push(User("map1zjgzk060jysve43ja9narcz9flw559fprktr6a", 331000000));
        _users.push(User("map1znk9cdukz8wktegah02ruz9e60y5e5vuvc6d62", 33000000));
        _users.push(User("map1zrzny77xp9dkfwdgs085j275w467ece2a3n5nq", 165000000));
        _users.push(User("map1zw0yx9emp4nfnjkg7axxrt4uedt46f8vzcmq56", 165000000));
        _users.push(User("map1zxarrqck36p5g7g9ej7qte2wz63mld33hecc2n", 165000000));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

