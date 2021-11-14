// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Base64.sol";
// import "hardhat/console.sol";


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external; 

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Widget is ERC721, ERC721Enumerable, Ownable {
    bool private _active;
    string private _baseURIextended;
    uint constant MAX_TOKENS = 10000;
    uint constant NUM_ATTRIBUTES = 3;
    uint constant GMGN_CHANGE_TEXT_REQUIREMENT = 10;
    uint constant GMGN_MINT_RECEIVE = 1;
    uint constant HR = 24;

    using SafeMath for uint256;

    struct WidgetRNG {
        uint timestamp;
        uint difficulty;
        string text;
    }

    string constant e = string('</text><text x="10" y="90" class="base">');

    mapping(uint => WidgetRNG) private widgetMap;
    mapping(uint => uint) private stakeMap;

    string[331] private smallPlaceNames = ['Zhoushan', 'Gwalior', 'Qiqihar', 'Klang', 'Yiwu', 'Weinan', 'Mendoza', 'Konya', 'Puning', 'Pikine', 'Turin',
    'Ankang', 'Mysore', 'Langfang', 'Jiaozuo', 'Liverpool', 'Saratov', 'Rohini', 'Columbus', 'Voronezh', 'Ranchi',
    'Weihai', 'Takeo', 'Ahvaz', 'Arequipa', 'Padang', 'Hubli', 'Zhabei', 'Xinyu', 'Marrakesh', 'Yibin', 'Denpasar',
    'Charlotte', 'Chenzhou', 'Jos', 'Valencia', 'Ilorin', 'Callao', 'La Paz', 'Ottawa', 'Chihuahua', 'Anqing',
    'Freetown', 'Jerusalem', 'Narela', 'Bogor', 'Mombasa', 'Xingtai', 'Cebu City', 'Niigata', 'Muscat', 'Marseille',
    'Zarqa', 'Hamamatsu', 'Zhaotong', 'Panzhihua', 'Boumerdas', 'Jalandhar', 'Chuzhou', 'Sakai', 'Cotonou', 'Salem',
    'Homs', 'Hohhot', 'Xuanzhou', 'Niamey', 'Tainan', 'Shangyu', 'Dammam', 'Xining', 'Anshun', 'Kota', 'Natal',
    'Jiaxing', 'Wuzhou', 'Antalya', 'Shaoyang', 'Da Nang', 'Trujillo', 'Malang', 'Bareilly', 'Teresina', 'Xinxiang',
    'Hegang', 'Riga', 'Amsterdam', 'Oyo', 'Deyang', 'Quetta', 'Yangquan', 'Ashgabat', 'Wanzhou', 'Zhumadian',
    "N'Djamena", 'Lviv', 'Edmonton', 'Jeonju', 'Saltillo', 'Bhiwandi', 'Pekanbaru', 'Sevilla', 'Tolyatti', 'Shizuoka',
    'Battagram', 'Changzhi', 'Bulawayo', 'Zagreb', 'Agadir', 'Sarajevo', 'La Plata', 'Tunis', 'Mexicali', 'Fuxin',
    'Enugu', 'Tangier', 'Huangshi', 'Liaoyang', 'Baise', 'Sanya', 'Sheffield', 'Seattle', 'Binzhou', 'Denver', 
    'El Paso', 'Kumamoto', 'Raipur', 'Dezhou', 'Dushanbe', 'Osasco', 'Detroit', 'Boston', 'Matola', 'Zaragoza', 'Gorakhpur',
    'Guadalupe', 'Ipoh', 'Sanmenxia', 'Athens', 'Leshan', 'Rizhao', 'Suining', 'Memphis', 'Puyang', 'Ansan-si',
    'Benghazi', 'Krasnodar', 'Palermo', 'Colombo', 'Lilongwe', 'Oran', 'Taguig', 'Ulyanovsk', 'Kotli', 'Okayama',
    'Chisinau', 'Hebi', 'Anyang-si', 'Jingmen', 'Portland', 'Winnipeg', 'Dandong', 'Izhevsk', 'Contagem', 'Bhilai',
    'Panshan', 'Djibouti', 'Las Vegas', 'Baltimore', 'Suizhou', 'Bristol', 'Chizhou', 'Taiz', "Ya'an", 'Borivli',
    'Yaroslavl', 'Bhavnagar', 'Benoni', 'Cochin', 'Jinzhou', 'Abu Dhabi', 'Haiphong', 'Sanming', 'Islamabad', 'Kirkuk',
    'Milwaukee', 'Vancouver', 'Situbondo', 'Barnaul', 'Rotterdam', 'Morelia', 'Luancheng', 'Rasht', 'Abeokuta', 'Essen',
    'Kayseri', 'Glasgow', 'Yingkou', 'Abuja', 'Zhangzhou', 'Stuttgart', 'Reynosa', 'Dortmund', 'Irkutsk', 'Blantyre',
    'Genoa', 'Oslo', 'Cuttack', 'Kerman', 'Chiclayo', 'Tlalpan', 'Umraniye', 'Shihezi', 'Kuching', 'Nyala', 'Asmara',
    'Sokoto', 'Onitsha', 'Wenchang', 'Sorocaba', 'Helsinki', 'Warangal', 'Siping', 'Kagoshima', 'Surakarta', 'Longnan',
    'Huaihua', 'Zahedan', 'Aden', 'Nanded', 'Orenburg', 'Changwon', 'Pristina', 'Jiamusi', 'Antipolo', 'Bremen',
    'Wanning', 'Xinzhou', 'Banqiao', 'Sargodha', 'Bangui', 'Vilnius', 'Kisangani', 'Port Said', 'Mersin', 'Tuxtla',
    'Raurkela', 'Warri', 'Guli', 'Tanggu', 'Shangluo', 'Tucson', 'Nashville', 'Beira', 'Guntur', 'Touba', 'Cangzhou',
    'Beihai', 'Hengshui', 'Macau', 'Bhayandar', 'Esenler', 'Fresno', 'Hamilton', 'Tyumen', 'Durgapur', 'Ajmer',
    'Lisbon', 'Guangyuan', 'Lipetsk', 'Siliguri', 'Hannover', 'Salta', 'Penza', 'Xianning', 'Tembisa', 'Bilimora',
    'Tonghua', 'Leicester', 'Barcelona', 'Zhoukou', 'Leipzig', 'Duisburg', 'Astrakhan', 'Pohang', 'Zhucheng', 'Loudi',
    'Cimahi', 'Wuwei', 'Jamnagar', 'Shanwei', 'Aracaju', 'Jianshui', 'Santa Fe', 'Toluca', 'Suez', 'Dresden', 'Tomsk',
    'Masina', 'Gulbarga', 'Mykolayiv', 'Najaf', 'Xichang', 'Shah Alam', 'Himeji', "Homyel'", 'Qionghai', 'Okene',
    'Yazd', 'Hargeysa', 'Sialkot', 'Kemerovo', 'Jincheng', 'Skopje', 'The Hague', 'Shouguang', 'Mixco', 'Lyon',
    'Londrina', 'Mesa', 'Jiaojiang', 'Matsudo', 'Tula', 'Kawaguchi', 'Nanping', 'Jammu', 'Liaoyuan', 'Edinburgh',
    'Heyuan', 'Atlanta', 'Kananga', 'Calabar'];
    
    uint8[331] private smallPlaceOffsets =  [8, 5, 8, 8, 8, 8, 21, 3, 8, 0, 2, 8, 5, 8, 8, 1, 4, 5, 20, 3, 5, 8, 7, 4, 19,
    7, 5, 8, 8, 1, 8, 8, 20, 8, 1, 2, 1, 19, 20, 20, 18, 8, 0, 3, 5, 7, 3, 8, 8, 9, 4, 2, 3, 9, 8, 8, 1, 5, 8, 9, 1, 5,
    3, 8, 8, 1, 8, 8, 3, 8, 8, 5, 21, 8,
    8, 3, 8, 7, 19, 7, 5, 21, 8, 8, 3, 2, 1, 8, 5, 8, 5, 8, 8, 1, 3, 18, 9, 19, 5, 7, 2, 4, 9, 5, 8, 2, 2, 1, 2, 21, 1,
    17, 8, 1, 1, 8, 8, 8, 8, 1, 17, 8, 18, 18, 9, 5, 8, 5, 21, 20, 20, 2, 2, 5, 19, 8, 8, 3, 8, 8, 8, 19, 8, 9, 2, 3, 2,
    5, 2, 1, 8, 4, 5, 9, 3, 8, 9, 8, 17, 19, 8, 4, 21, 5, 8, 3, 17, 20, 8, 1, 8, 3, 8, 5, 3, 5, 2, 5, 8, 4, 7, 8, 5, 3,
    19, 17, 7, 7, 2, 19, 8, 4, 1, 2, 3, 1, 8, 1, 8, 2, 19, 2, 8, 2, 2, 2, 5, 4, 19, 19, 3, 8, 8, 2, 3, 1, 1, 8, 21, 3,
    5, 8, 9, 7, 8, 8, 4, 3, 5, 5, 9, 2, 8, 8, 2, 8, 8, 8, 5, 1, 3, 2, 2, 3, 19, 5, 1, 8, 8, 8, 17, 19, 2, 5, 0, 8, 8, 8,
    8, 5, 3, 17, 20, 5, 5, 5, 1, 8, 3, 5, 2, 21, 3, 8, 2, 5, 8, 1, 20, 8, 2, 2, 4, 9, 8, 8, 7, 8, 5, 8, 21, 8, 21, 19,
    2, 2, 7, 1, 5, 3, 3, 8, 8, 9, 3, 8, 1, 4, 3, 5, 7, 8, 2, 2, 8, 18, 2, 21, 17, 8, 9, 3, 9, 8, 5, 8, 1, 8, 20, 2, 1];
    
    string[390] private largePlaceNames = 
    ['Shanghai', 'Istanbul', 'Mumbai', 'Beijing', 'Karachi', 'Tianjin', 'Guangzhou', 'Delhi', 'Moscow', 'Shenzhen', 'Dhaka', 'Seoul', 'Wuhan', 'Lagos', 'Jakarta', 'Tokyo', 'Taipei', 'Kinshasa', 'Lima', 'Cairo', 'London', 'Hong Kong', 'Chongqing', 'Chengdu', 'Dongguan', 'Baghdad', 'Foshan', 'Nanjing', 'Tehran', 'Ahmedabad', 'Lahore', 'Shenyang', 'Hangzhou', 'Harbin', 'Suzhou', 'Shantou', 'Bangkok', 'Bengaluru', 'Santiago', 'Kolkata', 'Sydney', 'Surat', 'Taiyuan', 'Yangon', 'Jinan', 'Chennai', 'Zhengzhou', 'Melbourne', 'Riyadh', 'Changchun', 'Dalian', 'Kunming', 'Nanning', 'Qingdao', 'Busan', 'Abidjan', 'Kano', 'Hyderabad', 'Puyang', 'Yokohama', 'Ibadan', 'Singapore', 'Wuxi', 'Xiamen', 'Ankara', 'Ningbo', 'Shiyan', 'Cape Town', 'Berlin', 'Tangshan', 'Hefei', 'Changzhou', 'Madrid', 'Pyongyang', 'Zibo', 'Durban', 'Fuzhou', 'Changsha', 'Kabul', 'Guiyang', 'Caracas', 'Dubai', 'Pune', 'Jeddah', 'Kanpur', 'Kyiv', 'Luanda', 'Nairobi', 'Zhongshan', 'Baoding', 'Chicago', 'Salvador', 'Jaipur', 'Wenzhou', 'Lanzhou', 'Incheon', 'Yunfu', 'Basrah', 'Toronto', 'Osaka', 'Mogadishu', 'Daegu', 'Maoming', "Huai'an", 'Dakar', 'Lucknow', 'Giza', 'Fortaleza', 'Cali', 'Surabaya', 'Nanchang', 'Rome', 'Mashhad', 'Linyi', 'Brooklyn', 'Houston', 'Nantong', 'Queens', 'Nagpur', 'Yantai', 'Maracaibo', 'Nagoya', 'Brisbane', 'Havana', 'Paris', 'Huizhou', 'Haikou', 'Weifang', 'Zunyi', 'Kowloon', 'Almaty', 'Tashkent', 'Algiers', 'Ganzhou', 'Khartoum', 'Accra', 'Guayaquil', 'Ordos', 'Sanaa', 'Beirut', 'Jieyang', 'Perth', 'Sapporo', 'Jilin', 'Bucharest', 'Camayenne', 'Nanchong', 'Indore', 'Vadodara', 'Nanyang', 'Fuyang', 'Conakry', 'Bayan Nur', 'Maracay', 'Medan', 'Chaozhou', 'Minsk', 'Budapest', 'Mosul', 'Hamburg', 'Qingyuan', 'Shaoxing', 'Curitiba', 'Warsaw', 'Bandung', 'Soweto', 'Vienna', 'Huainan', 'Wuhu', 'Rabat', 'Suzhou', 'Barcelona', 'Valencia', 'Pretoria', 'Yancheng', 'Zhanjiang', 'Taizhou', 'Aleppo', 'Manila', 'Patna', 'Manaus', 'Dazhou', 'Yangzhou', 'Kaduna', 'Guilin', 'Damascus', 'Phoenix', 'Zhuhai', 'Zhaoqing', 'Isfahan', 'Harare', 'Shangqiu', 'Kobe', 'Bekasi', 'Kaohsiung', 'Stockholm', 'Yinchuan', 'Manhattan', 'Jiangmen', 'Recife', 'Daejeon', 'Kumasi', 'Jinhua', 'Kyoto', 'Changde', 'Kaifeng', 'Karaj', 'Kathmandu', 'Palembang', 'Suqian', 'Multan', 'Liuzhou', 'Quanzhou', 'Puebla', 'Hanoi', 'Kharkiv', 'Agra', 'Tabriz', 'Gwangju', 'Bursa', 'Bozhou', 'Qujing', 'Fushun', 'Quito', 'San Diego', 'Fukuoka', 'Luoyang', 'Hyderabad', 'The Bronx', 'Guankou', 'Tangerang', 'Najafgarh', 'Handan', 'Mianyang', 'Kampala', 'Yichang', 'Heze', 'Khulna', 'Douala', 'Gorakhpur', 'Sharjah', 'Mecca', 'Makassar', 'Kawasaki', 'Baotou', 'Tijuana', 'Dallas', 'Medina', 'Bamako', 'Qinzhou', 'Luohe', 'Xiangyang', 'Yangjiang', 'Nashik', 'Semarang', 'Pimpri', 'Amman', 'Budta', 'Belgrade', 'Lusaka', 'Xuchang', 'Zigong', 'Munich', 'Xuzhou', 'Neijiang', 'Shiraz', 'Yiyang', 'Adana', 'Suwon', 'Jining', 'Milan', 'Xinyang', 'Liaocheng', 'Jinzhong', 'Adelaide', 'Meerut', 'Faridabad', 'Peshawar', 'Changzhi', 'Tianshui', 'Davao', 'Mandalay', 'Omdurman', 'Anshan', 'Depok', 'Saitama', 'Dombivli', 'Maputo', 'Taizhou', 'Rosario', 'Jinjiang', 'Guarulhos', 'Prague', 'Varanasi', 'Batam', 'Jiujiang', 'Sofia', 'Tripoli', 'Anyang', 'Hiroshima', 'Zapopan', 'Bijie', 'Monterrey', 'Samara', 'Kigali', 'Zhuzhou', 'Omsk', 'Malingao', 'Kunshan', 'Baku', 'Shangrao', 'Huaibei', 'Maiduguri', 'Meishan', 'Putian', 'Kazan', 'Yerevan', 'Amritsar', 'Fuzhou', 'Guigang', 'Hengyang', 'Goyang-si', 'Gaziantep', 'Sendai', 'Cixi', 'Yulin', 'Datong', 'Jingzhou', 'Tbilisi', 'Changshu', 'Xinxiang', 'Yichun', 'Taichung', 'Teni', 'Xianyang', 'Ufa', 'Campinas', 'Jabalpur', 'Shaoguan', 'San Jose', 'Longyan', 'Donetsk', 'Dublin', 'Yongzhou', 'Calgary', 'Brussels', 'Huzhou', 'Jiangyin', 'Odessa', 'Volgograd', 'Hanzhong', 'Hezhou', 'Dongying', 'Luzhou', 'Dnipro', 'Meizhou', 'Yueyang', 'Laiwu', 'Benxi', 'Perm', 'Srinagar', 'Zaria', 'Managua', 'Bengbu', 'Ulsan', 'Naples', 'Xiangtan', 'Linfen', 'Cartagena', 'Zhenjiang', 'Monrovia', 'Kingston', 'Baoshan', 'Erbil', 'Austin', 'Jodhpur', 'Chiba', 'Laibin', 'Madurai', 'Xiaogan', 'Ziyang', 'Sale', 'Quzhou', 'Bishkek', 'Abobo', 'Qom', 'Zaozhuang', 'Guwahati', 'Aba', 'Pingxiang'];
    
    uint8[390] private largePlaceOffsets = [8, 3, 5, 8, 5, 8, 8, 5, 3, 8, 6, 9, 8, 1, 7, 9, 8, 1, 19, 2, 1, 8, 8, 8, 8, 3, 8, 8, 4, 5, 5, 8, 8, 8, 8, 8, 7, 5, 20, 5, 10, 5, 8, 6, 8, 5, 8, 10, 3, 8, 8, 8, 8, 8, 9, 0, 1, 5, 8, 9, 1, 8, 8, 8, 3, 8, 8, 2, 2, 8, 8, 8, 2, 9, 8, 2, 8, 8, 4, 8, 20, 4, 5, 3, 5, 3, 1, 3, 8, 8, 19, 21, 5, 8, 8, 9, 8, 3, 20, 9, 3, 9, 8, 8, 0, 5, 2, 21, 19, 7, 8, 2, 4, 8, 20, 19, 8, 20, 5, 8, 20, 9, 10, 20, 2, 8, 8, 8, 8, 8, 6, 5, 1, 8, 2, 0, 19, 8, 3, 3, 8, 8, 9, 8, 3, 0, 8, 5, 5, 8, 8, 0, 8, 20, 7, 8, 3, 2, 3, 2, 8, 8, 21, 2, 7, 2, 2, 8, 8, 1, 8, 2, 20, 2, 8, 8, 8, 3, 8, 5, 20, 8, 8, 1, 8, 3, 17, 8, 8, 4, 2, 8, 9, 7, 8, 2, 8, 20, 8, 21, 9, 0, 8, 9, 8, 8, 4, 5, 7, 8, 5, 8, 8, 19, 7, 3, 5, 4, 9, 3, 8, 8, 8, 19, 17, 9, 8, 5, 20, 8, 7, 5, 8, 8, 3, 8, 8, 6, 1, 5, 4, 3, 8, 9, 8, 17, 19, 3, 0, 8, 8, 8, 8, 5, 7, 5, 3, 8, 2, 2, 8, 8, 2, 8, 8, 4, 8, 3, 9, 8, 2, 8, 8, 8, 9, 5, 5, 5, 8, 8, 8, 6, 2, 8, 7, 9, 5, 2, 8, 21, 8, 21, 2, 5, 7, 8, 3, 2, 8, 9, 19, 8, 19, 4, 2, 8, 6, 8, 8, 4, 8, 8, 1, 8, 8, 3, 4, 5, 8, 8, 8, 9, 3, 9, 8, 8, 8, 8, 4, 8, 8, 8, 8, 5, 8, 5, 21, 5, 8, 17, 8, 3, 1, 8, 18, 2, 8, 8, 3, 4, 8, 8, 8, 8, 3, 8, 8, 8, 8, 5, 5, 1, 18, 8, 9, 2, 8, 8, 19, 8, 0, 19, 8, 3, 19, 5, 9, 8, 5, 8, 8, 1, 8, 6, 0, 4, 8, 5, 1, 8];
    
    uint constant NUM_STROKE_COLORS =11;

    IERC20 private erc20_gmgn;

    constructor() ERC721("Widget", "WDG") {
        assert(largePlaceNames.length == largePlaceOffsets.length);
        assert(smallPlaceNames.length == smallPlaceOffsets.length);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }


    function _getAttributes(uint tokenId) internal view returns (uint, uint, bool [] memory)
    {
        uint nonce = 0;
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        WidgetRNG memory w = widgetMap[tokenId];

        bool [] memory attributes = new bool[](NUM_ATTRIBUTES);

        for (uint m = 0; m < NUM_ATTRIBUTES; m++) 
        {
            attributes[m] = false;
        }

        uint placeType = uint(keccak256(abi.encodePacked(w.timestamp, w.difficulty, tokenId, nonce))) % 10; 
        uint placeId = uint(keccak256(abi.encodePacked(w.timestamp, w.difficulty, tokenId, nonce)));
        if (placeType < 3) 
        {
            placeId %= smallPlaceNames.length;
            attributes[0] = true;
        } else {
            placeId %= largePlaceNames.length;
        }
        nonce += 1;
        uint strokeId = uint(keccak256(abi.encodePacked(w.timestamp, w.difficulty, tokenId, nonce))) %  NUM_STROKE_COLORS;
        nonce += 1;
        uint rarity_a = uint(keccak256(abi.encodePacked(w.timestamp, w.difficulty, tokenId, nonce))) % 10; 
        nonce += 1;
        uint rarity_b = uint(keccak256(abi.encodePacked(w.timestamp, w.difficulty, tokenId, nonce))) % 10; 
        
        // console.log("placeId: %d, placeType: %d", placeId, placeType);
        // console.log("rarity_a: %d, rarity_b: %d", rarity_a, rarity_b);
        if (rarity_a < 3) {
            attributes[1] = true;
        }
        if (rarity_b < 3) {
            attributes[2] = true;
        }
        // for (uint m = 0; m < NUM_ATTRIBUTES; m++) 
        // {
        //     console.log("%d: attrib: %s", m, attributes[m]);
        // }

        return (placeId, strokeId, attributes);

    }


    function _getGreet(uint nowh) internal pure returns (string memory)
    {
        if (nowh > 5 && nowh <= 10) {
            return string("gm");
        } else if (nowh > 10 && nowh <= 18) {
            return string("gd");
        } else {
            return string("gn");
        }
    }

    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function _getHeader(uint strokeId) internal pure returns (string memory)
    {
        string[NUM_STROKE_COLORS] memory strokeColors = ["00FF00", "1763cf", "9fa8b5", "3f8c55", "755b58", "e3d514",
        "d8ebdd", "ef46f2", "827182", "827f71", "3a23eb"];

        string memory a1 = string(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 220 168"><style>.base { font-family: consolas; font-size: 40px; stroke: #');
        string memory a2 = string('; stroke-width:0.5px;paint-order: stroke;  stroke-linecap:butt;stroke-linejoin:miter; }</style><rect width="100%" height="100%" fill="black" opacity="');
        string memory hdr = _append(a1, strokeColors[strokeId], a2);

        return hdr;
    }

    function _stakeBalance(uint tokenId) internal view returns (uint)
    {
        uint diff = block.timestamp - stakeMap[tokenId];
        diff = diff.div(60);

        return diff;
    }

    function _getSVG(uint tokenId) internal view returns (bytes memory)
    {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        if (stakeMap[tokenId] != 0)
        {
            return abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 220 168"><text x="10" y="40">Unstake to view</text></svg>');
        }
            
        bool [] memory attributes;
        uint placeId;
        uint strokeId;
        (placeId, strokeId, attributes) = _getAttributes(tokenId);

        string memory hdr = _getHeader(strokeId);

        uint offseth = attributes[0] ? smallPlaceOffsets[placeId] : largePlaceOffsets[placeId]; 
        offseth = offseth.mul(3600);
        uint nowh = HR.mul(block.timestamp.add(offseth).mod(86400)).div(86400);
        uint opacity = nowh.mul(100).div(24);
        string memory c = string('%"/><text x="10" y="40" class="base">');
        string memory f = _append(string('</text><text x="10" y="140" class="base">'), widgetMap[tokenId].text, string('</text>'));

        string memory placeName = attributes[0] ? smallPlaceNames[placeId] : largePlaceNames[placeId]; 
        string memory rarity_a = attributes[1] ? string('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" width="128" height="128" preserveAspectRatio="xMidYMid meet" viewBox="0 0 320 512" x="50" y="20" opacity="30%"><path d="M311.9 260.8L160 353.6L8 260.8L160 0l151.9 260.8zM160 383.4L8 290.6L160 512l152-221.4l-152 92.8z" fill="currentColor"/></svg>') :
string("");
        string memory rarity_b = attributes[2] ? string('<defs><linearGradient id="g"><stop offset="0%" stop-color="#e0e0dc" /><stop offset="100%" stop-color="#000000" /></linearGradient></defs><rect width="100%" height="100%" opacity="20%" fill="url(#g)" />') :
        string("");

        return abi.encodePacked(hdr, _uint2str(opacity), c, _getGreet(nowh), e, placeName, f, rarity_a, rarity_b, '</svg>');
    }

    function stake(uint tokenId) public
    {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        require(ownerOf(tokenId) == msg.sender);
        require(stakeMap[tokenId] == 0, "Already staked");
        require(stakeMap[tokenId] != block.timestamp, "Already staked");

        stakeMap[tokenId] = block.timestamp;
    }

    function unstake(uint tokenId) public returns (uint)
    {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        require(ownerOf(tokenId) == msg.sender);
        require(stakeMap[tokenId] > 0, "Need to stake first");
        require(stakeMap[tokenId] < block.timestamp, "err");

        uint b = _stakeBalance(tokenId);
        erc20_gmgn.mint(msg.sender, b);
        // console.log("unstake balance: %d", b);
        // console.log("erc20 gmgn balance: %d", erc20_gmgn.balanceOf(msg.sender));
        delete stakeMap[tokenId];
        return b;
    }

    function stakeBalance(uint tokenId) public view returns (uint)
    {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        require(stakeMap[tokenId] > 0, "token is not staked");
        require(stakeMap[tokenId] < block.timestamp, "err");
        uint b = _stakeBalance(tokenId);
        // console.log("stake balance check: %d", b);

        return b;
    }

    function setText(uint tokenId, string memory str) public returns (uint) {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        require(bytes(str).length < 10, 'Exceeded max limit (10) of string');
        require(ownerOf(tokenId) == msg.sender);
        require(erc20_gmgn.balanceOf(msg.sender) >= GMGN_CHANGE_TEXT_REQUIREMENT, "balance og GMGD tokens not sufficient");

        widgetMap[tokenId].text = str;
        erc20_gmgn.burn(msg.sender, GMGN_CHANGE_TEXT_REQUIREMENT);
        // console.log("setText after burn balance: %d\n", erc20_gmgn.balanceOf(msg.sender));

        return erc20_gmgn.balanceOf(msg.sender);
    }

    function mint(uint numTokens) public payable {
        require(_active, "Inactive");
        require(numTokens <= 10, "Exceeded max purchase amount");
        require(totalSupply() + numTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(0.01 ether * numTokens <= msg.value, "Ether value sent is not correct");
        for(uint i = 0; i < numTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
                require(_exists(mintIndex), "ERC721Metadata: nonexistent token");
                WidgetRNG memory w = WidgetRNG(block.timestamp, block.difficulty, string("wagmi"));
                widgetMap[mintIndex] = w;
                erc20_gmgn.mint(msg.sender, GMGN_MINT_RECEIVE);
                // console.log("after mint balance: %d\n", erc20_gmgn.balanceOf(msg.sender));
            }
        }
    }

    function svg(uint tokenId) public view returns (string memory) {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");

        string memory a = string("data:image/svg+xml;base64,");
        string memory b = Base64.encode(_getSVG(tokenId));
        return string(abi.encodePacked(a, b));
    }

    function svgText(uint tokenId) public view returns (string memory) {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        return string(_getSVG(tokenId));
    }

    function _rarities( bool attrib1, bool attrib2, string memory colorTrait) internal pure returns (string memory) {
        string memory rarity_a = attrib1 ? string(', {"trait_type": "Logo", "value": "Ethereum"}') : string("");
        string memory rarity_b = attrib2 ? string(', {"trait_type": "Gradient", "value": "Linear"}') : string("");
        string memory rarities = _append(colorTrait, rarity_a, rarity_b);
        return rarities;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_active, "Inactive");
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");

        bool [] memory attributes;
        uint placeId;
        uint strokeId;
        (placeId, strokeId, attributes) = _getAttributes(tokenId);

        string memory placeName = attributes[0] ? smallPlaceNames[placeId] : largePlaceNames[placeId];
        string memory textTrait = _append('{"trait_type": "Text", "value": "', widgetMap[tokenId].text, '"}, ');
        string memory placeTrait = _append('{"trait_type": "Place", "value": "', placeName, '"}, ');
        string memory colorTrait = _append('{"display_type": "number", "trait_type": "ColorId", "value": "', _uint2str(strokeId), '"}');
        string memory rarities = _rarities(attributes[1], attributes[2], colorTrait);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{ "name":"Good morning / Good night (Gm / Gn)", "description":"Gm / Gn tokens are a set of collectibles that are dynamic and self-contained on the Ethereum network.", "attributes": ['
                            , placeTrait, rarities, textTrait,  ']', 
                            '"image":"data:image/svg+xml;base64,',
                            Base64.encode(_getSVG(tokenId)),
                            '"}'
                        )
                    )
                )
            );
    }
    
    function activate() external onlyOwner {
        require(!_active, "Already active");
        _active = true;
    }
    
    function deactivate() external onlyOwner {
        require(_active, "Already inactive");
        _active = false;
    }

    function setGmGnAddress(address _addr) public onlyOwner {
        erc20_gmgn = IERC20(_addr);
    }
    
    function withdraw(address payable recipient, uint256 amount) public onlyOwner {
		recipient.transfer(amount);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Base64 {
    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory bs) internal pure returns (string memory) {
        uint256 rem = bs.length % 3;

        uint256 res_length = ((bs.length + 2) / 3) * 4;
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(bs[i]),
                uint8(bs[i + 1]),
                uint8(bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(bs[bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(bs[bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, ) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        for (uint256 k = j + rem + 1; k < res_length; k++) {
            res[k] = "=";
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}