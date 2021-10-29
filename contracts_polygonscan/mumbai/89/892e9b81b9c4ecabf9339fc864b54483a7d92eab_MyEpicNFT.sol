// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "./libraries/Base64Encode.sol";

contract MyEpicNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // This is our SVG code. All we need to change is the word that's displayed. Everything else stays the same.
    // So, we make a baseSvg variable here that all our NFTs can use.
    string baseSvg =
        "<svg width='217' height='217' viewBox='0 0 217 217' fill='none' xmlns='http://www.w3.org/2000/svg' font-size='20'> <rect width='217' height='217' fill='#E5E5E5'/> <g id='A4 - 1'> <rect width='595' height='842' transform='translate(-212 -178)' fill='white'/> <g id='Group 4'> <circle id='Ellipse 2' cx='108.5' cy='108.5' r='108.5' fill='black'/> <g id='Group 8'> <line id='Line 3' x1='36' y1='152' x2='182' y2='152' stroke='#ED1C24' stroke-width='16'/> <path id='DAO' d='M80.7598 113.32C80.7598 119.505 79.9062 124.478 78.1992 128.238C76.4922 131.999 73.9193 134.732 70.4805 136.439C67.0417 138.146 62.2051 139 55.9707 139H40.3105V87.6406H55.8223C61.8835 87.6406 66.6953 88.5189 70.2578 90.2754C73.8451 92.0319 76.4922 94.778 78.1992 98.5137C79.9062 102.225 80.7598 107.16 80.7598 113.32ZM69.9609 113.246C69.9609 108.768 69.5156 105.453 68.625 103.301C67.7591 101.124 66.2747 99.5651 64.1719 98.625C62.069 97.6849 58.9518 97.2148 54.8203 97.2148H50.8125V129.426H54.8203C58.9518 129.426 62.0566 128.956 64.1348 128.016C66.2376 127.051 67.7344 125.455 68.625 123.229C69.5156 121.002 69.9609 117.674 69.9609 113.246ZM84.248 139L101.244 87.6406H114.863L131.896 139H121.172L117.758 128.572H97.9785L94.6387 139H84.248ZM100.947 119.406H114.789L107.887 98.1797L100.947 119.406ZM179.582 113.32C179.582 122.251 177.689 128.943 173.904 133.396C170.144 137.85 164.664 140.076 157.465 140.076C149.87 140.076 144.279 137.738 140.691 133.062C137.129 128.362 135.348 121.781 135.348 113.32C135.348 104.81 137.129 98.2292 140.691 93.5781C144.279 88.9023 149.87 86.5645 157.465 86.5645C165.109 86.5645 170.701 88.9023 174.238 93.5781C177.801 98.2292 179.582 104.81 179.582 113.32ZM168.783 113.32C168.783 107.234 167.917 102.806 166.186 100.035C164.479 97.2396 161.572 95.8418 157.465 95.8418C153.358 95.8418 150.439 97.2396 148.707 100.035C147 102.806 146.146 107.234 146.146 113.32C146.146 119.406 147.012 123.847 148.744 126.643C150.501 129.413 153.408 130.799 157.465 130.799C161.572 130.799 164.479 129.413 166.186 126.643C167.917 123.847 168.783 119.406 168.783 113.32Z' fill='white'/> </g> <g id='Group 7'> <g id='Group 5'> <path id='Polygon 2' d='M88.4432 46.276L108.443 81.776H68.4432L88.4432 46.276Z' fill='#1C1C1C'/> <path id='Polygon 3' d='M128.943 46.276L108.443 81.776L88.4432 46.276L128.943 46.276Z' fill='#383838'/> <path id='Polygon 4' d='M128.943 46.2499L149.443 81.7499H108.443L128.943 46.2499Z' fill='#666666'/> <path id='Polygon 5' d='M108.443 81.7499L88.4433 117.776L68.4432 81.7499L108.443 81.7499Z' fill='#333333'/> </g> <g id='Group 6'> <path id='Polygon 2_2' d='M129 171.008L109 135.508H149L129 171.008Z' fill='#1C1C1C'/> <path id='Polygon 3_2' d='M88.5 171.008L109 135.508L129 171.008L88.5 171.008Z' fill='#383838'/> <path id='Polygon 4_2' d='M88.5 171.034L68 135.534H109L88.5 171.034Z' fill='#666666'/> <path id='Polygon 5_2' d='M109 135.534L129 99.5082L149 135.534L109 135.534Z' fill='#333333'/> </g> </g> <path id='SLG' d='M38.2269 59.308C38.9093 59.749 39.2873 60.3119 39.361 60.9968C39.4367 61.6783 39.1926 62.4554 38.6286 63.328C38.2385 63.9317 37.7991 64.3919 37.3107 64.7088C36.8243 65.0223 36.2679 65.1743 35.6415 65.1648L35.5148 63.569C35.8396 63.5557 36.1034 63.5146 36.3062 63.4456C36.5089 63.3766 36.704 63.2655 36.8914 63.1122C37.0788 62.9589 37.2542 62.756 37.4174 62.5034C37.6613 62.1261 37.7871 61.7911 37.7948 61.4985C37.8014 61.2004 37.6719 60.9655 37.4061 60.7938C37.2552 60.6962 37.1045 60.6523 36.9541 60.662C36.8057 60.6685 36.6477 60.7222 36.4801 60.8232C36.3093 60.9221 36.0586 61.1228 35.7281 61.4255C35.4039 61.7183 35.0925 61.9914 34.7938 62.2449C34.494 62.493 34.1927 62.682 33.8901 62.812C33.5896 62.9387 33.2805 62.9924 32.9628 62.9731C32.645 62.9537 32.309 62.8296 31.9547 62.6006C31.3084 62.1829 30.9458 61.6392 30.8669 60.9697C30.7848 60.298 31.0066 59.5553 31.5325 58.7417C32.2937 57.5639 33.2358 56.9915 34.3588 57.0242L34.5017 58.6166C34.0921 58.617 33.7498 58.6934 33.4745 58.8457C33.1993 58.9981 32.9578 59.235 32.75 59.5565C32.5422 59.878 32.4317 60.1787 32.4183 60.4584C32.4038 60.7327 32.5212 60.9505 32.7705 61.1116C32.9903 61.2537 33.2271 61.2579 33.4809 61.1243C33.7315 60.9885 34.0844 60.698 34.5396 60.2527C34.8016 60.0128 35.0681 59.7803 35.3391 59.5555C35.6067 59.3285 35.8887 59.1549 36.1849 59.0347C36.4833 58.9113 36.8006 58.8629 37.1369 58.8895C37.4731 58.9162 37.8365 59.0557 38.2269 59.308Z' fill='white'/> <path id='SLG_2' d='M41.7546 51.9055C42.8666 52.7727 43.5161 53.6581 43.703 54.5618C43.8923 55.4624 43.6375 56.3609 42.9384 57.2573C42.201 58.2029 41.367 58.6721 40.4365 58.6647C39.5053 58.6519 38.513 58.2347 37.4595 57.4131C36.3999 56.5868 35.7535 55.726 35.5203 54.8309C35.2864 53.9302 35.5382 53.0071 36.2757 52.0614C37.018 51.1096 37.852 50.6404 38.7777 50.654C39.7027 50.662 40.695 51.0792 41.7546 51.9055ZM40.7061 53.2501C39.9483 52.6592 39.3129 52.337 38.7997 52.2836C38.2859 52.2247 37.8296 52.4509 37.4308 52.9622C37.0321 53.4735 36.9227 53.9727 37.1026 54.4598C37.2818 54.9414 37.7503 55.4777 38.5081 56.0686C39.2658 56.6595 39.9028 56.9829 40.4191 57.0387C40.9346 57.0891 41.3894 56.8616 41.7833 56.3565C42.1821 55.8451 42.2918 55.3487 42.1126 54.8671C41.9327 54.38 41.4638 53.841 40.7061 53.2501Z' fill='white'/> <path id='SLG_3' d='M46.6263 52.5667L40.7158 47.0144L41.8471 45.8101L46.6558 50.3273L48.9907 47.8418L50.0925 48.8769L46.6263 52.5667Z' fill='white'/> <path id='SLG_4' d='M54.6143 44.8149L51.6863 47.4124L50.8426 46.4612L51.6885 45.7108L47.9945 41.5467L47.1486 42.2972L46.3048 41.346L49.2328 38.7486L50.0766 39.6997L49.235 40.4463L52.929 44.6104L53.7705 43.8638L54.6143 44.8149Z' fill='white'/> <path id='SLG_5' d='M59.1841 36.1995C59.7638 36.9853 60.1215 37.6972 60.2571 38.335C60.3927 38.9728 60.322 39.5613 60.045 40.1006C59.7681 40.6398 59.2336 41.2016 58.4414 41.786L56.4516 43.2539L51.6375 36.7281L53.6084 35.2741C54.3786 34.7059 55.0723 34.3665 55.6896 34.2557C56.31 34.1427 56.9038 34.2435 57.4709 34.5581C58.0356 34.8696 58.6067 35.4168 59.1841 36.1995ZM57.805 37.2023C57.3853 36.6333 57.018 36.2538 56.7031 36.0638C56.389 35.8684 56.0543 35.8095 55.699 35.8871C55.3436 35.9648 54.9035 36.1972 54.3786 36.5845L53.8693 36.9602L56.8886 41.0529L57.3978 40.6773C57.9228 40.29 58.2732 39.9393 58.4491 39.625C58.6259 39.3053 58.6665 38.9623 58.571 38.5959C58.4754 38.2295 58.2201 37.7649 57.805 37.2023Z' fill='white'/> <path id='SLG_6' d='M67.0393 36.1077L63.6878 38.1293L63.031 37.0406L63.9994 36.4565L61.1243 31.69L60.156 32.2741L59.4993 31.1853L62.8508 29.1637L63.5076 30.2525L62.5442 30.8336L65.4193 35.6L66.3826 35.0189L67.0393 36.1077Z' fill='white'/> <path id='SLG_7' d='M69.576 27.3504L72.4722 33.2783L70.9876 34.0037L68.0913 28.0758L65.8486 29.1715L65.185 27.8132L71.1551 24.8964L71.8187 26.2546L69.576 27.3504Z' fill='white'/> <path id='SLG_8' d='M78.9254 27.2078L80.0244 30.0997L78.4689 30.6908L77.3824 27.8317L73.2166 24.0116L74.9036 23.3705L77.5875 25.9799L77.8941 22.2341L79.5208 21.6159L78.9254 27.2078Z' fill='white'/> <path id='SLG_9' d='M91.946 26.7278L90.4832 18.7514L92.1085 18.4534L93.2986 24.9428L96.6528 24.3277L96.9255 25.8146L91.946 26.7278Z' fill='white'/> <path id='SLG_10' d='M98.6844 25.624L97.9239 17.5504L103.168 17.0564L103.305 18.509L99.7058 18.848L99.8679 20.5689L102.901 20.2832L103.039 21.7416L100.005 22.0273L100.188 23.964L103.787 23.625L103.929 25.1301L98.6844 25.624Z' fill='white'/> <path id='SLG_11' d='M104.649 25.06L107.315 16.9446L109.465 16.9397L112.173 25.043L110.479 25.0468L109.937 23.4016L106.814 23.4086L106.29 25.0563L104.649 25.06ZM107.279 21.9603L109.465 21.9554L108.367 18.6063L107.279 21.9603Z' fill='white'/> <path id='SLG_12' d='M117.307 25.4848L115.511 22.2473L114.676 22.1749L114.411 25.2337L112.765 25.091L113.466 17.0119L116.402 17.2665C117.441 17.3566 118.184 17.6092 118.63 18.0243C119.08 18.4397 119.268 19.0736 119.194 19.9259C119.135 20.6147 118.941 21.1508 118.614 21.5341C118.29 21.9177 117.857 22.1429 117.314 22.2095L119.192 25.6483L117.307 25.4848ZM117.519 19.8512C117.554 19.4387 117.473 19.1532 117.275 18.9949C117.081 18.8369 116.745 18.7372 116.266 18.6957L114.988 18.5848L114.801 20.7389L116.009 20.8436C116.379 20.8757 116.666 20.8653 116.871 20.8125C117.075 20.7596 117.227 20.663 117.325 20.5225C117.428 20.3824 117.492 20.1586 117.519 19.8512Z' fill='white'/> <path id='SLG_13' d='M125.286 26.7034L123.418 20.4737L122.381 26.1751L120.79 25.8858L122.241 17.9072L124.35 18.2909L126.076 24.1611L127.054 18.7825L128.651 19.0729L127.2 27.0515L125.286 26.7034Z' fill='white'/> <path id='SLG_14' d='M132.66 28.5599L128.888 27.514L129.228 26.2888L130.318 26.5909L131.805 21.2269L130.716 20.9248L131.055 19.6995L134.827 20.7453L134.487 21.9706L133.403 21.67L131.916 27.034L133 27.3346L132.66 28.5599Z' fill='white'/> <path id='SLG_15' d='M139.73 31.0472L139.02 24.5821L136.968 30.0014L135.456 29.4287L138.328 21.8449L140.333 22.6043L140.967 28.69L142.903 23.5775L144.421 24.1523L141.549 31.7361L139.73 31.0472Z' fill='white'/> <path id='SLG_16' d='M149.535 29.1218C149.494 28.7292 149.376 28.3962 149.178 28.1228C148.98 27.8494 148.679 27.6149 148.275 27.4194C147.61 27.0981 147.025 27.0796 146.518 27.3642C146.017 27.6469 145.563 28.2103 145.155 29.0543C144.75 29.8913 144.599 30.5755 144.702 31.107C144.811 31.6367 145.19 32.0588 145.841 32.3733C146.333 32.6114 146.836 32.7287 147.35 32.7254L147.898 31.5912L146.474 30.9026L147.109 29.5891L150.026 30.9994L148.465 34.2279C148.005 34.3179 147.486 34.3187 146.909 34.2303C146.334 34.1436 145.782 33.9718 145.251 33.7151C144.111 33.1642 143.397 32.4522 143.108 31.579C142.818 30.7058 142.989 29.6169 143.62 28.3121C144.866 25.7343 146.623 24.9937 148.892 26.0904C149.553 26.41 150.076 26.7997 150.461 27.2593C150.846 27.7189 151.064 28.2252 151.113 28.7784L149.535 29.1218Z' fill='white'/> <path id='SLG_17' d='M163.267 37.8575C163.299 37.4641 163.242 37.1151 163.097 36.8106C162.952 36.506 162.698 36.2212 162.335 35.9559C161.739 35.52 161.167 35.3964 160.617 35.585C160.073 35.7727 159.525 36.2449 158.971 37.0016C158.422 37.7519 158.151 38.3978 158.156 38.9392C158.167 39.4797 158.465 39.9633 159.048 40.39C159.489 40.7129 159.963 40.9189 160.469 41.0082L161.212 39.9915L159.936 39.0574L160.797 37.8799L163.412 39.793L161.295 42.6872C160.826 42.6928 160.316 42.6 159.763 42.4089C159.214 42.2202 158.702 41.9516 158.226 41.6034C157.204 40.8561 156.63 40.027 156.502 39.1159C156.375 38.2049 156.739 37.1645 157.595 35.9949C159.286 33.6839 161.148 33.2722 163.181 34.7598C163.774 35.1934 164.218 35.671 164.514 36.1925C164.81 36.714 164.933 37.2512 164.882 37.8042L163.267 37.8575Z' fill='white'/> <path id='SLG_18' d='M165.092 47.0218L165.575 43.3514L164.947 42.7966L162.914 45.0975L161.676 44.0035L167.045 37.9263L169.254 39.8777C170.035 40.5682 170.482 41.2131 170.594 41.8122C170.709 42.414 170.483 43.0354 169.916 43.6765C169.459 44.1946 168.984 44.5104 168.493 44.6238C168.005 44.7398 167.523 44.6631 167.047 44.3936L166.51 48.2749L165.092 47.0218ZM168.614 42.6196C168.888 42.3093 168.993 42.0316 168.928 41.7866C168.866 41.5441 168.655 41.2638 168.295 40.9457L167.333 40.0961L165.901 41.7164L166.81 42.5195C167.088 42.7652 167.325 42.9276 167.521 43.0068C167.717 43.0861 167.896 43.0985 168.059 43.0442C168.225 42.9924 168.41 42.8509 168.614 42.6196Z' fill='white'/> <path id='SLG_19' d='M174.649 50.9421C173.623 51.9093 172.649 52.4167 171.727 52.4641C170.808 52.5143 169.959 52.1258 169.179 51.2987C168.357 50.4261 168.02 49.5305 168.168 48.6119C168.323 47.6935 168.886 46.7761 169.858 45.8597C170.836 44.938 171.785 44.43 172.705 44.3355C173.631 44.2413 174.505 44.6305 175.327 45.5031C176.155 46.3814 176.492 47.277 176.338 48.1899C176.19 49.103 175.627 50.0203 174.649 50.9421ZM173.479 49.7013C174.178 49.0422 174.593 48.4631 174.724 47.964C174.861 47.4651 174.706 46.9797 174.261 46.5079C173.817 46.036 173.34 45.852 172.831 45.9558C172.328 46.0598 171.727 46.4413 171.027 47.1005C170.328 47.7596 169.912 48.3401 169.778 48.8418C169.65 49.3437 169.806 49.8277 170.245 50.2939C170.69 50.7658 171.164 50.9497 171.667 50.8457C172.176 50.7419 172.78 50.3605 173.479 49.7013Z' fill='white'/> <path id='SLG_20' d='M179.194 57.7263C178.196 58.5102 177.319 58.8706 176.564 58.8075C175.81 58.7444 175.064 58.2443 174.329 57.3071C173.6 56.3791 173.29 55.5405 173.397 54.791C173.509 54.0423 174.069 53.2724 175.077 52.4813L178.792 49.5652L179.812 50.865L176.189 53.7086C175.756 54.0487 175.448 54.3579 175.264 54.6363C175.08 54.9146 175.001 55.1902 175.027 55.4632C175.052 55.7361 175.201 56.0462 175.474 56.3934C175.862 56.8881 176.264 57.1313 176.68 57.1229C177.098 57.1121 177.621 56.8607 178.248 56.3687L181.889 53.5106L182.909 54.8103L179.194 57.7263Z' fill='white'/> <path id='SLG_21' d='M185.013 62.9881C184.192 63.517 183.458 63.7157 182.811 63.5842C182.166 63.456 181.565 62.9585 181.006 62.0916L180.276 60.9587L178.168 62.317L177.273 60.928L184.09 56.5358L185.74 59.0971C186.238 59.8688 186.441 60.5811 186.351 61.2342C186.264 61.8851 185.818 62.4697 185.013 62.9881ZM184.08 61.5611C184.464 61.3135 184.673 61.028 184.706 60.7046C184.741 60.3844 184.581 59.9485 184.226 59.3968L183.778 58.7023L181.488 60.178L181.853 60.7445C182.181 61.2534 182.442 61.5826 182.636 61.7319C182.835 61.8824 183.043 61.9431 183.262 61.914C183.482 61.8882 183.755 61.7705 184.08 61.5611Z' fill='white'/> </g> </g> <text transform='translate(108.5,195)' text-anchor='middle' fill='white' font-family='Roboto Mono'># ";

    event NewEpicNFTMinted(address sender, uint256 tokenId);

    constructor() ERC721("Solidity Learning Group", "SLG") {}

    function fillerZeroString(uint256 _nftNum)
        public
        view
        returns (string memory)
    {
        string memory _filler = "";
        uint256 digits = 4;
        while (_nftNum != 0) {
            _nftNum /= 10;
            digits--;
        }
        while (digits > 0) {
            _filler = string(abi.encodePacked("0", _filler));
            digits--;
        }
        return _filler;
    }

    function makeAnEpicNFT() public {
        uint256 newItemId = _tokenIds.current();
        string memory placeNumber = string(
            abi.encodePacked(fillerZeroString(newItemId), uint2str(newItemId))
        );

        string memory finalSVG = string(
            abi.encodePacked(baseSvg, placeNumber, "</text></svg>")
        );
        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bankless DAO SLG # ',
                        // We set the title of our NFT as the generated word.
                        placeNumber,
                        '", "description": "A token to show membership in the Bankless Solidity Learning Group", "image": "data:image/svg+xml;base64,',
                        // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(finalSVG)),
                        '"}'
                    )
                )
            )
        );
        // Just like before, we prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, finalTokenUri);
        _tokenIds.increment();
        emit NewEpicNFTMinted(msg.sender, newItemId);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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