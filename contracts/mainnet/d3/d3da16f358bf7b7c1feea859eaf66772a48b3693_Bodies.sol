//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Trait.sol";

contract Bodies is Trait {
  // Skin view
  string public constant MOUSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAACbnZmoqqf3ocW1t7TCxMH6uNXP0c7/0ODy9PBk4k/iAAAAAXRSTlMAQObYZgAAAlFJREFUSMftlEGumzAQhnMFp0ZZg+AAT9l0a/SPvDaakdULoGwjYaGuK6EcoG/BbTsOpM0T5PUCbxYJyJ//sWeY/3DQ4JTIHCtzeBXCIlVlypcAJUlG47XCmOQ/AH8OsBB/Chgb8nr1EjgX4Wyqah8gYXMGzm8gJhHZAC7Kt+8iv95EYGOkDWDHhLwT4kWftwoco2RAaAwUxy1ANEoNFYiRKSVsgEL7ULOGT20p0m4AAHJk/UlwFdy2YQYGR6UYzpmy3aumyDQt//K3I8z99AT0/QOwgMvPXj4ATworYIdl0wawepClAZfLulwHO4Ko0q2mqoG2alsYg5zuDjSdT0BRAlFGUUBJ0lsrwEuClpOWQQE/zwNQH8VZtlFr7xbA6SeLOivMs2rVPnHBpPXFQwFX5sYBP+b5XYEmdZRoUIW0AvbKaFrIz3n+rajEzjMNTCvQdKeBWTqSrCDcxNjZq9Vj2XAHjgFX7WcrWeE9KwS2wepxi2Fpdwc9UNMtgFaE9BbhpAqe1xR6i6zAMV+TapAr+ClF1eYPrmq1Rvdroqq1ULbve1oUpts09f3lAhjiAC6NLfP77XbpD1/xFa9D1oFlfvGpPHzCy0tgUZBnb9gDCNO0swyMTu3MZUe2xmIHKBw4D5A4jyLsADqy3OgIJlcEj31gIFXI4Do0HzwbPujAqRsT1B2GreuTz2coWZXUv7cA6BQ8q8PpfmLvdqoQHYWjGpwf7EB7wOmqgA65DDQUvAMUan9N0BSOnB32ALaonRqDcxbbFHdPuEzT7e4X/7z+D7sW7hfwM1TYAAAAAElFTkSuQmCC";
  string public constant MOUSE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAFlUlEQVR42u1bO2/bVhQ+JMSkZho7bYcCHCR09NwOUn9B58JAli7N0h+RuXPm7l2y9CdkjIQAnT3LKAhkSNG0AB2YQtiB/MjvHt5LXsXUwwYPIJCiJYrn/Z2HA+mh4u/fCsmvRE7mIptUZJKUx/xKJJqKvH/ZfDiaNef5WkREgm9eBXLENPH6VDRtmOZrmmliXKJZc36nBQBNTxL1TViCg8k7wLyISOilfWYagtikch8o3Pob2hXuOPnFAGYYLqGv31sB1FF+KRIv2pHf6TqzeyKAeFEes6UZD/j6HWJYU1C8fV4YjMG0wRgY7aJsaX5Ou4i+Pz/Al78cFCeEhpkjwuOBK6aKxxflNXoVjy/a2QIvZj5bNue4/yQ5mvgR1trjh1OaDz68aWvuw5uWoGrGJ4kpDM38Ju20iv0K4OypmdcBdzUDXTghmjYaPZmbARSBk3GDBlUHDYJIa9pMa42mdmCk/RtoEQLUlsF/OyIsETZRvBLCJrWjPLYGxgJ4zwIEg3lavt6/NC3MJdyDWEC8aAMdQ9Nru+Z1YWTTbL4u02M0M69ny6MpliatdFe/70CDNqSoGcT9mMl8XcWE46kUA2v9z+8/+06Cm0spHpxLcHMpwZOfgt7+gReydDxQT/+g7k/AZR+el9c9n29rJBjcXBrHQcgFrmB9fXUJmjMDpNLearB4cG4cByEfRru+e71qgalPVVB4EMfT8SZb+guFcUVlAbdRUlD89XMhUWJWefGiATTXKzPaw/+y6nqUdGuYi6TIAYA4HUZJ+Z6PNquBELUbAHyBwa9/DfpjAPf3oqRhXuMBFElnlCI1U9FU5Kt5813dQXJlE74PznH/aNrOSn3+z+Cu0wXieTv/a61ryfelRBGR0wuRJ89E4u/Ll6sAgpazZXWuIDiKKVxjS7BBargIV7TeMSBft1FeCwWmfj3E8LQ54rxLa/FC5PRHsyK1mTkY1O6plcDf9xYA/BWaQkzQQommbn8WEfn8h/L48d/yJVJaQWd6s0DwPG2YQIHmU1ABmXqkydA7RdnM1whwU3v7nC2BBakFGs/NatSIVD0FlEai2xVDq/YDIQjaujx4UM0AiLUI5mENNuY1o115H+kSRZutYct/9+hdhpKvm5QGrA7f4koRx2xlSlwzY2MCbtBXV4Cpdy/amUG7h48LeMeAWqsz8wddN+hrlmiG2RK4muRYwkI5e9odxU/m7sEMulueg5vQ2s3tCyIun4PpZa8tpvzanQZZKNZYo1pvrujPLuMJuUsglK3aUb1LgozQbJrNr8qoH56W1sBpsDVkSbrTa11WK8GEj+pKsFtgr7qh8MfszwLlLhcWKC9dBVL9mf/+sGcRztc8SufcXneN1hawVV3/4lnn79uqV372bcvjkUYaaaSRRhpppJFGGmmkkUYa6f7T4M2C1n5A+MhoYITxt1vP/3fZ4NjLdHirHQPM/0X2skq3FwFsNb7G6JtmiYMuZxxCAFsRmp9VZ3cnCxpDxoDi7XPT53mvgNvSxtL1rJkIY1FTCwCLVnzU95L++X8fTQYX6bsXJlO6CxzNaBDTsY8YkxB4+5S31n3W9vfuApjMuMbbWtMtlah5Q7Zs1mF4rzm/8ttk37sFOH8pMQch0dQ+DLle0XDWIlyRRiADrNsOYwGudGWb5kL72cq9LGkbhetV/oEWrsNBmLdNinFNm2lu2e/DOI33jfVKzI7+S+32AtCa0iN1zgwiVfSvZpF6h5gtwLZxjt+bJO0sc7AYoLWJDMCMQXv6/4viuV0AbN7ZsowFJ/TZAa1h+CyA1MRa3yZu6H+u4CGrtrABssBukOAmNWf0HA8YB9jyOCNBNnF+DzcYIjntLO1huZEf2hY3Hp77WxVrfKAYcHso/M/vha34ce0c8LnvjN9VYH3Kerym/wFb+eX9GW42nAAAAABJRU5ErkJggg==";
  string public constant FROG =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEUAAAA7lEpEpFNNsmA+uFVLy2R565KV9mKK+Xuu+YeVjfWeAAAAAXRSTlMAQObYZgAAAoNJREFUSMftlcFu3CAQhvcVwFvlzMAqe4Uh7V6Dh8NeHVAfodpjUinWvkFybKKsy9t2bGerpLbTF8hcQPbHD8x4fq9WHAF8Nhbr1VLUiaIQFS4DOYXGUFwGYq4T0H4RiIkBattFIKVMzf5YPlCIN7vHh4+AHHePZR5IMRHkDCbHmCnlCeATcRYykefXMU+vauroTYKgfb8R0QQg01DalTuNiYg2MAEghNDwAe+IIk/9BNAQsCmlPKmrRAam9QCQbssKnfcJtHMTAMHpr6xQdJ3RIcxkAnFMkdbotMV1P6/wTeL/At/ao7DrQaPWpZsAeOxKLdZ2mOvyVuFw6EdX2s5coxzUXp/1t7DeATgQalt+l/Js1mupUJvIX+m43nGlAEQltv1dflkFwYMzlF01AEqmBgBdZXcDwHnzCMB1VWNWhcIAoJSU/RdRnkLFiO638GMbOBXDBqy1YgCeeXVlEIgSjIDlKvIplB0SXmRwFSEGrr0LI6ASH1MLYbcPDFQo7do5k3Kq9ABIlZqcpVKKFZ64vUAiIotmHCtreY+clXQqMCAdWn6PkQHxCsgNK2hUkh7Kpuov3ANNOitc/Ny/5Hx5i8JsIfT6PZBLm167/f7+dDiW9qjcl2ACb+A0tt3h0HbHbvUZn7Ec5y53YsFSz4D3/wHemcd74HQa+30c/wkh9A1oKVIO7FXg5gBQQmBKwVl2vjngSmLFxhB0jc7OAKYWCIoy8XpHM8DmykrNXUnaAlzPAWy00sacAPEa585QW6cUGwNbEPo5IGrtZEo3gbvXzbi+IcU+kiP/E+aBTeTWZzuKiQ9TzQD7l4vby7vvpTTILjAB2vZ0Ovxo2RZOp46H8/M/lvTY1DIlh4sAAAAASUVORK5CYII=";
  string public constant FROG_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAIVBMVEUAAADPtCThwyXw0Cf+2xv+3TL/4Eb95Fr/8a7+9cX899RhptAzAAAAAXRSTlMAQObYZgAAAp9JREFUSMftlb1u2zAQx/0KNMt0tg0P7SaxZ8PZkiLeqfORtbfEpdNdoPkKjbYUKBB5K9wiMp+ylOx2qOT0BXIaSIg/nO6Lf/V60TJJfqyIeuds4cgwJs4D6BFv+XByFiCixWcGq7OAWXsiWX49C+RuQ3erXTjvgYxb7srw0ifMche6AWccSe8leGM8Od/OwMVH38dE4rHxpgUAGQInMa7Om45qEuRkl2EP0RHRVLYAiYh5DHBPZOK27QEk0jpEIInRgmwDUnKcRQ+ByElAbMcQ4/sUz8MkpoEkO1t1LNGCCOGKRL3nuggtAJZVwZRIGxhCG5jvDoGYUB1AUTRjE8oqDh6v95PTu/o4zqKUOGLJLBxC+AlC9AcWAO5BHQGMnZKyL9iszuWHGgwzShHkPTbh9jLucikJx2rZACMk0qkku0luGmCgCKVUyUjUExH2mRgijQDm/tQ4TA1OpVJZvwF+UX8kRKweutERULGLPl4bRU3BOa5F7Cpq6++OZVepi2ECY2pWRuANcSWsBbe1p4vEU5d7zwdJEj3sB4JSruvx8v7D6RPKOu9TjkOMACet5pa08ZYYndKcRg9AA05lmAqy6wutyeRrZ4/Au++rZ+8vHxdDmMlsyMle6I31obRaN0D1VBW7UBUZvkXAG0VyrMtQFOVhd+i92qv1XpD0442+Y2ck9Q9A8B8Ax+FwBqiqevXr4/qPMQYOQfTdNopu1s+6ABowRrlDVBLHXYDhJKIwIGjCqy5ADylNaEPyetwhyYxNjRpB/VeA21SqLiAKbT/T1smNVl0eJqQ+JondOpwT2S7AACC3a4c3RFmH6tcSoBKrQW6svu4ApvGHJNBsjdN2IzqA1fP7x8tvX0LINXUEWZZVVTw8RFmoqkN4+tuu37PtHby9UpV8AAAAAElFTkSuQmCC";
  string public constant CAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAKlBMVEUAfoMAAADfhAbme6LykxL1qUH3s131uGb6vXLxu871woDw38b369768eo1FJ5bAAAAAXRSTlMAQObYZgAAAn1JREFUSMftVbtq41AQ9beYbbfdLwhmN72E6l17Msh2G4Lr9TAkcbeNIemCCfoAEdBNawgzt9kiWET6lx1JTgjRtfcHMhi50NGcM4977mBgAQAUWQwOBSJjlBwBADOoxTEAHgUQ038ymMijgBOEkxcVdxAwHI2H+nAdBgDhzyHQ8AshxCa2LxDg91eGv98BcGJiAiXS+AfgnxEyQELUz4BoPwQk46C4T4EA9ilh+zhb9jMwCJgOAGdkpqOvQYqi+PXNHg4wCWSYOhXJp87+8niZQKATqrVvyfbREVfVO4CvPwKQuo/2gPLpFfA6MqCn8j2g/AhgKF8B4ipRHUG2mKluswVC1OxPU3hLNihc7VUhShdXzj2nC14urWdgiH3JTrRQncglT+URLxkijJmaFJOuZBVvFIXLzuYiu+wMExsLUDO5jkKtQ6ZM0nQlLk9TZI5hZmsOHHcitXqxDDmncxXilJacWfsbHR0FOjQNSpt0/uJxk9IETmcqj6ahy0BEV6pMGZPIc2a9uLybWukAUdKN2yQbI2d2uBxmnMB4I977Zk32GUwWo1Fcq9tu0mSZjURrtf3ptnzXDmi1u7+YWTX3FxGfoqt8DSDtCAf1uixri+zcatXsPE7vJn79VAL4wyftMz6jOcSdJwBX/gDA+703VAcAnU8g3NweApQdxe1t8LXtrINxawzMEAAUVeGi5upo7SEAcF6dxPaSzXYpBHgUlcIAZtyd1/UyNG5qCq63gHGYopjamVyZKUMow8NcCe1dUemWlgFAbtdGcytILXngauK9UYC5dJUHKBqTsLAm+NrKpXCG1WpngMpL3b8i67os1+YTADc360rf5vkPQ7rZon2nXVAAAAAASUVORK5CYII=";
  string public constant CAT_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAHlBMVEU3ZmbWs/X+2Q7/4lj853H864r/8779+NX9/PP8//vaF3CyAAAAAXRSTlMAQObYZgAAAlRJREFUSMftVUGO4kAM5C0ItA9I8gEoC+YK9i65r1acVwxp7gx23zea5LfrTmA1Ghr2A2NFOaQrrnLbXT2ZeADgwmPyKIiEiuoJACIwj2cAegpg4f9kcJFPAVPC9N00PAbMFlN73eUBYFpMwdMpE0oXey8Q2HwT/J4DtHQxmRJ5MQdtZiRAxXyfgcgfArFzcHlPQYD/yjS8sL3PIFC4DiA4meu416DNr2Yx81cAVZkMq72pHlYh2OVQbitkdsKsjwPZNUbirvsAiP1nAPH40xXQvt0At5aB39qPgPYzQNDeALrv1GzmM7M2O3szUKT5SYUPZJNj6KMZCpYfIfxhke3W9wyOuJYcLnY0WyrTSk++6yioFE4plmPJptEpmiD0otoKUeVtAafOjRTmG+XKVFBfwk8BiZRY+5hDylGkde+e4eAZ7OKpeeuL2iQdIwUFcg3m7Xx5j36CeIn52vTkGsYMzPzdTNhHXzVVIbJZhU6BohrbLemjt5pgwauosGCNMaYxuWZwWU4ttLNwFu+4zNR68/kZp7wdGlS3TGtNUgqZU+hiD+jQwkkvbdt7pD6oeY20WUZ5a4H4+KR9xVekQzx6AqSLDwAxXr2hewAYfYKwqx8B2pGirrPLPrMBi8EYRJABNN0xFOnqGOwhAwjR9lr6orjtcgawP6lp4wBKHpADxL17hSvYnUFlFmDNys9k7aaMXIbXFz+avtZ0duZtBnDwayPdCtrrIXM1ydUo4C7dHTIUySQ8fBNib0E5n6Gu07Hvovb3V2Tft624TwC7nXT2r59/AQMDMqrp7GQzAAAAAElFTkSuQmCC";
  string public constant APE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAGFBMVEUAAAA7DwhHEwdaGAhoGwh3Iw2nfibBkCsdplZnAAAAAXRSTlMAQObYZgAAAlhJREFUSMftlMFu2zAMhvMKloz2LFLLzuIvt+dYwnpfugdYW1jnZYD0+qPjYCtmu09QAolh8/Ov3yLFw0EDz3EIydBhLxLSWYzILpDzAICwC4xAdID7YAkMDuP+En5MoyWx+wrnZ2CaPvCQvu8DzEyZxY+IxOA1RAP6h1LZ8qi7kddAGNg8tMo0/BA/8LACJEUcWyWDjC/nvP5UieBja+RjdIOMae0BXp5qu7hwFh6wLphIwrfSXkmYLTYKxl3HmEo0hjsC88ZOAK0u1yWu9XXNvgPKCnDc3t4rtP8Bf1O9Rk91pTCilFs6MhHQ64+1XHNE8RT/dVikRIKTAE+t/Na0pjjOL9i49IJozDiearno45G1qIZnqWUnkwnCyETUJup5JAhGUBTJV8DCOGHTSz6W+pYY1qseBepuhRvBogoJdFfaJWXR28AcKISlcIHJCXGW7nGaXpCi8ZwDkQ2yfIWHFV2xE/+11F+qF1WvI3G4dVfMRm0pk1Cb5rX71a/WNtxMIpF+BcMg3l30fMoJ8GoikbsBfP+TQHNj6WtZe7vnx9eHFxdSfwVaq6W1VljgSDdgzCdtj6LPej58xmfsh6C0ZWpx2QQgbZqvBvdtB6jXhJG6o4ByVfDSymaanJ4rPeXB5YCwBehZonkS6DjkbgMwoM7N48OfWHgDYGdGo6fQI+jA3ARits6RkZP+bwA2zNMnKND1JFsmA50g7EgCkLZMBhg2sWMhM2ID6Jz1ksiy0yFgNwA3D1NY3YugM2kDuLvogFGvx5fHV6xN6pyYytSm2kqp1fz18Acnz6v6AMt3MQAAAABJRU5ErkJggg==";
  string public constant APE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAG1BMVEWjTRz73ET/6UP/8UP+90P//8D9/9v9/+/+//sa9BhIAAAAAXRSTlMAQObYZgAAAlxJREFUSMftlc1q5DAMx/sKkg0zV8mC7tVWDnu1o6V9ku65S2FynXYhfuxVJlkWNpk+QQUmIfmhL1t/Pzy4jTYMeQR+uGdttJGA7gNmQ1KGct+DjQZc4D7QBiNt9S4gzVoAwk9ycHt5sU9yaA5cjoEQApg0qSrALaQdAMLxaZpjCNXbYftSyRL86LOgWBGTfRhuAz/2mWG0JGb7UrNZeuzdHRhIaeM+hyHS89yvQEZBDrqZc+Onqb8RxRi05H2ZAMEukwEiYMF00AnWPi9P3ezWW+r/Gq/a+/8AYP/9KRA3rzeLsA/R0jRtv4cEoBrJ1+XnqJqKUPSOqG5nVMCwaM2qz72/q0phCRJRFWXdauZatMANuLqfiti8Yo+17guMWEtiA4h9bhErJNLKIDmvADJSSRibnab5bWR/ZQaoAEY3oHJcPIxK56lfRyPMRBgrUG7reUCgwsEyPF8u72UUiGjEhMRbFSk25QEonvt8bRqEUgNsoLZ6EAPSQgxWeq/J/QVfXANtSeqtCt/HIqcrsBfNKZKIl7oCjOdXViDx4aRguuTw7f3plajFG9D7PHU3pqXnjavVcumTf4v3J+3LvszPd1mnvAhOh0Aq/fYD07kfA3n1ANtzZ7qJhuR+FMKPPrHfK6rZBVHoCGjG4DqBIXCCQwAAkgOxhhwOgEiwiANJIZQ9wOwDZ0guqNXF4SAH14nKqHmZ7IiHSVauyeUCW9bU9l1wIIFrE/hg++tBCL8Xo9/gIVLOB1fkIgGJA2OClgmOqjhdWwkp4enX9w/eJ+k6cXGZ8DVN8wz69/sfNbmlnl7guAkAAAAASUVORK5CYII";
  string public constant ALIEN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVzLWlnyeJtzudn3PqA4PnR7JeRAAAAAXRSTlMAQObYZgAAAbNJREFUSMftleuR6zAIhdMCchoQuAEDDTjQf033IN9kkvixM/t7Scbj2J+OJNAhtxvCLLw35ttZGIt1IjoFlFowXygAkEsgOl0DWKGIXi1S2SDRz4FwI3oc7yIR5mFuOWIPhOeSOaXjrWfsd2A2xsZQMtvPv0xqtpot92Cz/U5ksQ4RE5u028FOWLSLZcPoTtz2AHHvjEQ0UaKjgtEzmI8BTMKtvTJi2z4i1/UN6P0H4DcK/gKcxmGaMtfW7rh2mpFWr/xuqcYoTDJXJTxfgQrEBmTV2nRUI4qwGv8GuEf9iFFKXOsXSK9nn4DZmBc6hvvcKcSQ5rQFxydl8J9AaK0WFsKCXFz1C4Aq6wwClVdjBypfwEMFR3vCnlmlxDYFGAKOUOg/5geARnCx4IPvF4BnuGsd52aLbYpWT6jj2D2k1kCNCAlfie7321/8xXk8XR725uxPYHP5m7NPOo3/TgG2Mp6Uyp9+1LOrt1hUU4W346Bn47XH6Avp5fUDIOK/Db24C8AKyHNAfC7oFIDFQ9D7TwG0BRcQ5wBcrU/rf+ZRdWsFuDOWKyAP/4UJfaJ6xXdv+Ad3ppnSV1byKgAAAABJRU5ErkJggg==";
  string public constant ALIEN_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAD/64b+7I//76H+99H//fOpxc4dAAAAAXRSTlMAQObYZgAAAb5JREFUSMftlduN6zAMRNMCIacB3woE0gUYJAswTPXfyg7lTW4SPxbY72UCw7GPRhKpYW43hFl4Lcy3szAWq0R0CiiVYL5QACCXQFS6BrBCEb1apLJBop4D4Ua0Hu+iIczD3FqPPRDe5taG5njrLfY7MOtjoyuZ7eefBzVbzOZ7sNl+JzJbhYiJDVrtYCcsWsVawehKXPYAca2MRBRRoqOC0SOYjwFMwqU8M2LbPqItywtQ6w/AbxT8CTj1wzS0tpRyx7XShLR65ndLNUZhkikr4e0ZqEBsQMtam/ZqRBKW418A98gf0UuJa/4C6fnsHTDr80LHcN92CtGludmM49Ok8+9AaK4WFsKCXFz1A4Aq6wQClVdjByofwKqCoz1gz6ySYpsCDAFHKPTXaQVQCC4WfPD9APAMd6Xi3GyxTVHwZBwrjt0quQYqREj4Mo73++0v/uI8Hi4Pe3H2O7C5/MXZJ53Gf6cAWxkPSulPP+rZ2VsssqnC23HQs/Hao/eF5un1AyDi24ae3AVgCbRzQHxK6BSAxUPQ+08BtAUXEOcAXK0P67/nUXVrBbgzliugHf4Lj/9qzV6RvYHof2/4Au0Iyq3lC/iXAAAAAElFTkSuQmCC";
  string public constant DOGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAOVBMVEUAAGc7LRZhSi6EYS+wgjevj1nHlUTPnEPQnVLfpEzaplPNqmzdqE/Xsm7jv4DwyoXtypf10Zf50ax+6m1uAAAAAXRSTlMAQObYZgAAAvFJREFUWMPtl9uW2jAMRWkaJFtxY4f//9ieIzkktJ3B0Fc0TJZDrB3dbIvLpUuWlFPKOYkk/l9elQxlqHb9twCSNQmVKfo6ACbAiNwB8jJAU1a34W2AKtSpv7i8DEjKNIhcr1eoX5e3gsgouP4rFiB4eK/ik4uUvCCOWZX5TG7SUwBmYb4qtEvJua43ArwYPCjPAXxj0lSYR0u3223NQib0IQOAhImaa62p2Fq31toKPbxbHT0GgP5a27ZOP27QXxcWNdM6Asg0oNZl+bUs9ecEdQwYWeqngSAmriDPfMgvXlCUKaI7YAGqn4A7wfX7skyDq9IgjN6prF2sy/G9CKZtbwMEhC8B0zZtzwGSt7b9BwAmnOeFcjETMd9I5hnlXESKB/TqYwkW8sIISOENqldOgGIoXd9EFgdA2oJqquY4PorHXHEBSKcNx2DCbNqnwBpOWde6rFU5pgmuyou5vj7sWCXcVDHaV/iZFRYAYD6+vxy3d4Admy6stNwB0j0wFDTEXQjfe0BDXwk7A7CSweCLwutiFT6sq4/dAbhYGCx8gMJH7C8L4L2JT5sFgCWCOHsSjH/MliEbbkmxhxhkPiPAnzELjGENd/h6PMK8wnT/WRssojI7wBi0okiltso0+jh83y8ldwMeXfAYGlMYABKww6iPfXpEgD51VDkAjcujOVm7B6r8UjV8uBMK5oUtrR2AbZsm1DeWSEhUX2Rrz6qHBTK1iYvW5fKRj3zkI2/1C9hhtlc2EQK4RR0A0fYyAPvXqbHQf/YF37qAjfLoC0TO90+VsT1L7KUYKtvgOKB5Hfjd4A2H9APBN2g/IDUahVFAP0pK6Wej0Qw2DM8BtN9yjtPg1Czx8NIhAO12QJzmO0F5Po26kAmwA+AHIxGqYwCc+BFD6y0aj3eHjFmgiMF+zDqA/VNP61AdUKXsUcTt7s9DZ/IdQPArtERH4X3DXPakjgKan+J+0kc/sLVofdpzAHsELiQ0DS7eDLCB+KIv+A3z8j1xfknTpQAAAABJRU5ErkJggg==";
  string public constant DOGE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAJ1BMVEUAAAAAAAANDAB+aQD73T3+5m3964L87JD88KH/87z+9cb8+t/8//sh9bMDAAAAAXRSTlMAQObYZgAAAndJREFUSMftlcFuo0AMhvMsPecxeknvhk601xkJ1CsibPfakES9QvCUY8qurbxANresVInsPNR6krTaCmhfoBbSIPPF/DPYf0YjiSJLMQmTcDQUawxTSOEDQOUhAASDAGYZCgCDQF6p/ENgscwTYOZBYBau4fqGJx+IzLJrZOwXmMLDrZ0+IS7SJMmSDhBW+eKZqXa4CJPbKu0ACvOc1vjDtWqRLHHdrbCsave9ds7hLF1i3gOgPDyMnduFs+WyC1T4+Pdp92fs9rieVeuuyCS93032iPsdPiTZoisS4R43+JsQqzQJ074viiLCr0YCJU73cM4NAoF+B4zHHUB9AoA55yQsggW4/rXiDe5vVhwYE2kDU2NUcQZoqgE2PyO7rds2sgEE0nwQGxOeGwhpYiRj5/bO1S9zCyYArVVjzKXD5ABKBQ2V8V1dt2Us5XRQkgfKE8BEAkwZjXywFo28X6RaERxcAGYsQHHqgWMqeWWILZkyUm8VUAUkFdpWKhhTlhZVHKGliwYqUClE3rbuiFyUuiAL9vVERmgnBWLMpeyiPcqPUS6SDn5tYiZMEKdcrRrnXqoVMYoEuxHKnoCtSEOMbLWaO2cEsGQt+9z2eALc1VjazTn2h6xlT8Ts3Dk3+oqvGI5XG9BmoFXegGAQOBxO3mA+AQDOa+fxvGArI2qetQ607gAGQQAqjGm00dAL+IlhmU2MA910gChSfiRkeCMxjLIHwMAScemdrCTb9wrlZ1aAWAyBTB9gZXAFaAoiKnqASCR6DQR+uz3n4J2Hm6hk8ZaLu7wHAk0WxUxuPNgHfBOn4GfxBbGCbdsB5G/pcOVNQdb/veEfCqS+LlEIo/sAAAAASUVORK5CYII=";

  // Front view
  string public constant FRONT_MOUSE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAAD3ocW1t7T/0ODCxMGoqqebnZnP0c7y9PD6uNUYO1c3AAAAAXRSTlMAQObYZgAAAK5JREFUGNNVjjEOwyAMRX2FqDewEMwdWS0rdK7UC6Ak7ChKOlcZvDPltgWTDvX09OD7GwAGxAHa3JjvCoaZ/+GJjB2ISGEm7GZGhQXt8npiBOTAO7OFGJxIXi0YCiKrIzD5IXIYrPAW+VQTSU2G2MzhMiRqwNW0VDZ1z4k1flooZTE0el/b4r5bbXfr1IFagd78A9zcqBA31/+knMbrKXSDlLYrde0xPPW496UAfAHzjTeL5IzRoQAAAABJRU5ErkJggg==";
  string public constant FRONT_FROG =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAABEpFNLy2Q+uFVNsmCK+Xuu+YeV9mJ565I7lEplCHFxAAAAAXRSTlMAQObYZgAAAKtJREFUGNM1z8ENwyAMBVCvYHAGwGQBQ5Q7bSJ1gfTeSLVy7RIZoBMXcMPp6WP0DQAgM0I7OXHu8BGlI6766QhPVYP+MVzJwxLyg75VCEqFqhTAvDZQvVrrcMaWNBBIas8j1qZhqxDIXJPXKJBYKjxCCnlTlyKw+gFFA5znV7wcR227Fxp7OzPZ8jHQrWMRP3UkcZbE7BZDoekaTjYcvX3ZBWfJvM97x3G2ph+xUif8/19AxAAAAABJRU5ErkJggg==";
  string public constant FRONT_CAT =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADfhAb3s136vXL68erykxLxu87w38bme6L3697kvRXPAAAAAXRSTlMAQObYZgAAALlJREFUGNM1j0EKwkAMRXOFgidICtXtRJAu1dIyF/AGLrqthWG2HkEGP7mt05n6V4/3E0KIqGHX0JaD8rXAg+VZQES4ALOTAo65mnB8hwJYuriN8snsk0uWS4w3x6TSYRVRctoCdxFSPSMu2lPQ1uDOgbC2U5LgycMBNwyUElsU72mw3uInZTOcYJY8fUcz2Dznax6Gcn1IeXmLhZgKJMS1GuzGTztIeLX1i8uyv6PqaqVajf7NmEP0Az2IOx+h0qlJAAAAAElFTkSuQmCC";
  string public constant FRONT_APE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAFVBMVEUAAABoGwhHEwdaGAinfibBkCs7DwicKfTcAAAAAXRSTlMAQObYZgAAAK1JREFUGNMtz01ywzAIBWCu0B8fwA9Xe4tE+7qiB3Ch+ypO7n+EKsJs+GYeM8wjohfOMz3nosYBP7G44YQHJvN94F39a0Cqrn2twrVKSfSHyfUHTI0n051nEsArZiGURe2zZeJyqO8dwLXWDR35Q+2XnxDzV07EvB5769FlY2ReNlKVBFHt3wCk8f0NkIGcW6AVjqilE5xvZQAJgVtugYZH3KCkKHj/PqKgqVWif1kQJtsU7kIuAAAAAElFTkSuQmCC";
  string public constant FRONT_ALIEN =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAABn3PqA4PlnyeJtzuejFreRAAAAAXRSTlMAQObYZgAAAIJJREFUGNOVjssVAkEIBDsFkATomQTUTYDZzj8m2dGL3qwDr3h8AZin4eJG3rew2WI27CP2ljIeW2ShLc/mmvFxHI+eY9KdzJZkOh3eeWY6jOa9yFHcXQvlYaZKyKlY1SWbUaWCaq5ZEqSOIWKMWbHG6Gsp/TyW3nu3NP9LNN9yNsALJUcY7sDqAgYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgCAMAAAAsVwj+AAAAM1BMVEUAAADIlUPPm0Leo0veqU/WsnTxyoTQnVHaplPzy5rjv4BhTC48LBXLqm+vkFnmqUqugja3Zpx/AAAAAXRSTlMAQObYZgAAANxJREFUKM9Vj1l2xSAMQ/EQR0CJs//VVn5thqePBN+DJdQaJWoublu7xMndLB5gthv2foOI3THiATz3MX8esLZtxZwPOIpQz41jre0CIswssB3uokKg7n2NsQKuBeo3RqwRCgWaF+ANgprRakYfJah+gAPBnTGcbqCHJsEq01RUCtJ7eYYnRBrgqT0q1tP/PE4nCcae5dF7r1xK1flts88u+pHwOP/7IFEJlySVHV/g5BsJcANWUG7lDbKA2gskTMzs+wbwtSL69jgLsPQrham66w1YIaV6XKo+V49fUFgJhmcLhjkAAAAASUVORK5CYII=";

  string public constant FRONT_MOUSE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAIVBMVEUAAAD/6Xv+9s//7pn/5GH/30L/8rP//O3//vv/8KT+9s1LjXuuAAAAAXRSTlMAQObYZgAAALVJREFUGNNVjjEOwyAMRX0FF8HeI1hWUNZIvQBKwo5Q0u4ZmrVTuEK4AbcsATrU09PHzx8AwDxwzY35XkAw8z8MyHVnIKICEzVrqvqMcn4MaABZ88oswWi1v52XIEiH4BWBcP2xbwIzvI7wyYmhPoRNODDuFY5NObD0zAnn5LKcyHdO3Hd/SohxFtSllNvMusrSrvxYga6C8ucf4KK6AmZRdcc627UnXRMkuzSr3RE8Vj2lGAG+jVgvhr3EkdsAAAAASUVORK5CYII=";
  string public constant FRONT_FROG_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAHlBMVEUAAADw0Cf95Fr+3TL/4Eb+9cX899T/8a7hwyXPtCT2V0zAAAAAAXRSTlMAQObYZgAAAKRJREFUGNM1z9ERgzAIBmBWQMwASSYgqO1r6wz2Xe+KGzhIJy4hMU/fwc9BAABTQqhPprc4KCM71ll3R/yoOl7aEe7Ko1WIgn6VCdigygwocwVZa7awICA7LDPV8Yy2KWwGBklW2Q0lsYEQSpRNh5IhKQV8aoTr+jHxedZThbJvT4nazTlSab9gmhyFh1bJMvQMj3d4bK019/Eh9vByLIfjvOqmP4ELJ1XM0kwpAAAAAElFTkSuQmCC";
  string public constant FRONT_CAT_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAGFBMVEUAAAD+2Q7853H864r9+NX9/PP8//v/877neKqBAAAAAXRSTlMAQObYZgAAALRJREFUGNM1j0ESgjAMRXMF1AuYAHsbwbXYwh6TugfKAZzh/pYW/+rN+8lkAgAFmgL2XBifCc5ItwREhAkQDSUwiNnY68kmkK50+yhWqmMske7OTQaBqZSeiMFwLTITAXP7cV9uwHKtH9NakL5ePNkAQYzIJCt4j+ooBFi1UTf6aNZKVH2A96wq2jTxWhCVdH31cXmPDs4n8LL12ciWTVgOoOFV5y8e3fEOs8kVczb8N3MMwA/sISy7wemIKAAAAABJRU5ErkJggg==";
  string public constant FRONT_APE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAG1BMVEUAAAD+90P/6UP9/+/+//v73ET//8D/8UP9/9uzqmsUAAAAAXRSTlMAQObYZgAAAK5JREFUGNM1z1EOwjAIBmCusDr0uTWNz1p2AWEHgI14jyXGA3hxu67y0i9/IQQAGGKIsNeJWBvOwkdyFU4dYg0jy9yb5d4wFBrqEzct38s7g9oo8rQX+I7ZFJKrcIgbOC7Ed0NQXKl+BUh5LOVZYWEVnmNNcBNBzRBjXGb3AKcpeX4tDyC6uX+I6jZ3y8d2q8N7JeywfbghdygqNni2Axrsn3hvxo51Wo4DmbgA/ACHzic41uzVBwAAAABJRU5ErkJggg==";
  string public constant FRONT_ALIEN_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAD1BMVEUAAAD+99H//fP/64b/76E/c53eAAAAAXRSTlMAQObYZgAAAIJJREFUGNOVjssVAkEIBDsFkATomQTUTYDZzj8m2dGL3qwDr3h8AZin4eJG3rew2WI27CP2ljIeW2ShLc/mmvFxHI+eY9KdzJZkOh3eeWY6jOa9yFHcXQvlYaZKyKlY1SWbUaWCaq5ZEqSOIWKMWbHG6Gsp/TyW3nu3NP9LNN9yNsALJUcY7sDqAgYAAAAASUVORK5CYII=";
  string public constant FRONT_DOGE_GOLD =
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAgBAMAAADpp+X/AAAAJFBMVEUAAAD+5m388KH/87z+9cb8+t/8//v87JANDAB+aQD73T3964LSVpU9AAAAAXRSTlMAQObYZgAAAMhJREFUGNMtzzGOwyAQBdC5AouVxkfYyhrCFq6iQS5MuckJQCOvUq0U5QhcxLkAiuWGyy1mloan0UefAYAP053hOBdHtoG+8NnAD8sCXlLD+ftHsN4QG2a8Ur1UN+PtdcmgtsmG4DNov7O9jwjkd2vDG8EUyxxKBVXEjUBvNRv8AMpMgSMpQLdziK5mZs98fxFwLMxlYkipLyUvy9FmPofW3mUlWIuS/+ConWwx9qbBocb/iZYJDW/JrEMhefXbZ9k0nmTllI6mPyFUO1tjRrmRAAAAAElFTkSuQmCC";

  constructor() {
    _tiers = [
      2500,
      4500,
      6500,
      8000,
      9140,
      9940,
      9950,
      9960,
      9970,
      9980,
      9990,
      10000
    ];
  }

  function getName(uint256 traitIndex)
    public
    pure
    override
    returns (string memory name)
  {
    if (traitIndex == 0) {
      return "Frog";
    } else if (traitIndex == 1) {
      return "Mouse";
    } else if (traitIndex == 2) {
      return "Ape";
    } else if (traitIndex == 3) {
      return "Cat";
    } else if (traitIndex == 4) {
      return "Alien";
    } else if (traitIndex == 5) {
      return "Doge";
    } else if (traitIndex == 6) {
      return "Frog Gold";
    } else if (traitIndex == 7) {
      return "Mouse Gold";
    } else if (traitIndex == 8) {
      return "Ape Gold";
    } else if (traitIndex == 9) {
      return "Cat Gold";
    } else if (traitIndex == 10) {
      return "Alien Gold";
    } else if (traitIndex == 11) {
      return "Doge Gold";
    }
  }

  function _getLayer(
    uint256 traitIndex,
    uint256,
    string memory prefix
  ) internal view override returns (string memory layer) {
    if (traitIndex == 0) {
      return _layer(prefix, "FROG");
    } else if (traitIndex == 1) {
      return _layer(prefix, "MOUSE");
    } else if (traitIndex == 2) {
      return _layer(prefix, "APE");
    } else if (traitIndex == 3) {
      return _layer(prefix, "CAT");
    } else if (traitIndex == 4) {
      return _layer(prefix, "ALIEN");
    } else if (traitIndex == 5) {
      return _layer(prefix, "DOGE");
    } else if (traitIndex == 6) {
      return _layer(prefix, "FROG_GOLD");
    } else if (traitIndex == 7) {
      return _layer(prefix, "MOUSE_GOLD");
    } else if (traitIndex == 8) {
      return _layer(prefix, "APE_GOLD");
    } else if (traitIndex == 9) {
      return _layer(prefix, "CAT_GOLD");
    } else if (traitIndex == 10) {
      return _layer(prefix, "ALIEN_GOLD");
    } else if (traitIndex == 11) {
      return _layer(prefix, "DOGE_GOLD");
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./ITrait.sol";

abstract contract Trait is ITrait {
  bool internal _frontArmorTraitsExists = false;
  uint256[] internal _tiers;

  /*
  READ FUNCTIONS
  */

  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    public
    view
    virtual
    override
    returns (string memory layer)
  {
    return _getLayer(traitIndex, layerIndex, "");
  }

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_");
  }

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    virtual
    override
    returns (string memory frontArmorLayer)
  {
    return _getLayer(traitIndex, layerIndex, "FRONT_ARMOR_");
  }

  function sampleTraitIndex(uint256 rand)
    external
    view
    virtual
    override
    returns (uint256 index)
  {
    rand = rand % 10000;
    for (uint256 i = 0; i < _tiers.length; i++) {
      if (rand < _tiers[i]) {
        return i;
      }
    }
  }

  function _layer(string memory prefix, string memory name)
    internal
    view
    virtual
    returns (string memory trait)
  {
    bytes memory sig = abi.encodeWithSignature(
      string(abi.encodePacked(prefix, name, "()")),
      ""
    );
    (bool success, bytes memory data) = address(this).staticcall(sig);
    return success ? abi.decode(data, (string)) : "";
  }

  function _indexedLayer(
    uint256 layerIndex,
    string memory prefix,
    string memory name
  ) internal view virtual returns (string memory layer) {
    return
      _layer(
        string(abi.encodePacked(prefix, _getLayerPrefix(layerIndex))),
        name
      );
  }

  function _getLayerPrefix(uint256)
    internal
    view
    virtual
    returns (string memory prefix)
  {
    return "";
  }

  /*
  PURE VIRTUAL FUNCTIONS
  */

  function _getLayer(
    uint256 traitIndex,
    uint256 layerIndex,
    string memory prefix
  ) internal view virtual returns (string memory layer);

  /*
  MODIFIERS
  */
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
  function getSkinLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory layer);

  function getFrontLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontLayer);

  function getFrontArmorLayer(uint256 traitIndex, uint256 layerIndex)
    external
    view
    returns (string memory frontArmorLayer);

  function getName(uint256 traitIndex)
    external
    view
    returns (string memory name);

  function sampleTraitIndex(uint256 rand) external view returns (uint256 index);
}