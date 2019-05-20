[CmdletBinding()]
param(
	[Parameter(Mandatory = $false, ValueFromPipeLine = $false,ValueFromPipelineByPropertyName = $false)][string] $computerName = $null
)
Begin{
	clear;
	$error.clear();
	Add-Type -AssemblyName System.Windows.Forms | out-null
	Add-Type -AssemblyName System.Drawing | out-null	
    Add-Type -AssemblyName System.security | out-null

    Add-Type -assemblyName PresentationFramework | out-null
    Add-Type -assemblyName PresentationCore | out-null
    Add-Type -assemblyName WindowsBase | out-null
    add-type -assemblyName System.Data | out-null
    
    $global:imageList = new-Object System.Windows.Forms.ImageList
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 16
    $System_Drawing_Size.Height = 16
    $global:imageList.ImageSize = $System_Drawing_Size

	$icons = @{
		'folder' = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAEUklEQVR42u2WTYgcVRDH681k14yaHKIBMYoYjeawIBoWFBRlVVZiEC+CIhE8xFPUq7kIAb14MAgePPkRRZQseBQVPHjRHQ1pCUFwTUBMNisz+zHZmdme6X6v/L9X9Xom2WS3Bddc0kzR3e/1vPrVv+pVt6GrfJhrAJcOnPq8dttIlT6rVunRS+f+nOP3Jw6mb+NyAdbfEIA/jtUa2+954eatdzxHxD0itwLrEmWL1Jj5gr75/uTU/sO9N/DoX/8FxCqA01M13jnxEZxaAGB9Toldh0x+Ae6aNPPTh9Tq8NmRqmlXKmTDCsb/zOrVhodwMfbiylOqXndtgEfegeOcyMJpbxGOYd0GeJbIZF1yPnADc7C8TxWAOn9tczIVgBs3WL0CGzF0+twm2vV8+hLufvDZXBtg/FU4hfP2WViTslaDOp0lyjijFWsptQ4O+V/LnWbUv/9A+jQuf4R1Lg9wDABjeylrnqFW8zz1R7bRTfe9RqPX74DTlKqjW6GO03/GEGFGz8QyH+oHSrsLEBOq5/P069dHMgAcwkNfwc5cFmDmyxpvouvohlsnaNvu/VTdvB2LZVoPuRqLI8OyRDjFpZw843rg6JKxLWK7iBpaoBPffpI/8Ep6BA99Cju5CuDU0drhClXe3LHnddpy+6TMshUAn+MIQTl8CoRhlmsftfWRNrFjmiFisvMBgFwb0z1KphtrA/z28Wbe+cR7NLrlLokkLGw1agXAQlhZx3viKG/A6d8wFCrgDIAZwIbyAB7HTkw31wfY/ezUQGIFYMpQ2BHCO10Qpz5ayCsKyTwHhUQp47Iw5//v55N6GYBnjoZrz2BCPq1G4LflEtaew5pzuO+Is2gBEs7g0JBXQJWgrABM6vMlAPZ9oMNOKLzUPufZLLb+LCDa4T6O+4WDQgEkK4yLez3j2WR6oQTA3ndF/ZAAh6h8Gz4HdedC7k1MC9uQY+/IqAocHKkSqlpQRIGS+lIJgMm3dIthyi7D8WzIs6TDqTIOTwBAdwiT7hQPpVGznkM6FDCpt9YHuPfJQ8E3WzSq7Lxso+KIRSm1YWIqgiK5Oo9QAwXi1k3qyyUUePygRAjn5J37FwrLrvc1EZQg79AN6kC3qqTEFvXAWiPxueTndgkFHnsZUc+H9mmGpj2C0YYzUMBJ5B7IO6IIJCYgUi8C0C0B8PC+0FBirzcUa5JVAZac+xpwCnPRrhiG0EL1Y8YCIC2Rggcfkm8ANsE9F+/02Jx81DykgHZFI0UpteBEfh7UiAdOfumXUGB8TKLE282I6EUSTOhO0h847goFiSpIDVgFcENtGwDH8xIKjO/CnysqvSmKP9zh7Re6tDoPCoR08JD0A6cCYoux5LgrocCeO0MPCBM8/E3F2p4l+nAunEl/CMXI9uLIKfYOD0DrA9AGHiv9dQBw3A2b1PNGHF6O32Hf0RW+iG6E3aLnjTi8wsswfDxc4Zvw/z6uAVx1gH8A72icTrkYCVcAAAAASUVORK5CYII=";
		'computer' = "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";
		"filesystem" = "AAABAAEAICAQAAAAAADoAgAAFgAAACgAAAAgAAAAQAAAAAEABAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAACAAAAAgIAAgAAAAIAAgACAgAAAgICAAMDAwAAAAP8AAP8AAAD//wD/AAAA/wD/AP//AAD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB4iIiIiIiIiHAAAAAAAAAAf////////4hwAAAAAAAAAH93d3d3d3eIcAAAAAAAAAB/iIiIiIiqiHAAAAAAAAAAf/////////9wAAAAAAAAAAd3d3d3d3d3cAAAAAAAkAAAAAAAAAAAAAAAAAAAAJAAeIiIiIiIiIhwAAAAAACZAH////////+IcAAAAJmZmZB/d3d3d3d3iHAAAAAAAJkAf4iIiIiIqohwAAAAAACQAH//////////cAAAAAAAkAAHd3d3d3d3d3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHiIiIiIiIiIcAAAAAAAAAB/////////iHAAAAAAAAAAf3d3d3d3d4hwAAAAAAAAAH+IiIiIiKqIcAAAAAAAAAB//////////3AAAAAAAAAAB3d3d3d3d3dwAAAAAAAAAAAAAAAAAAAAAAAAB3d3d3d3d3d3d3AAAAAAAAf//////////4h3AAAAAAAH93d3d3d3d3eIdwAAAAAAB///////////iHcAAAAAAAf4iIiIiIiIgoh3AAAAAAAH+IiIiIiIiIqIdwAAAAAAB////////////3cAAAAAAAB4iIiIiIiIiIiHAAAAAAAAB3d3d3d3d3d3dwAAAAAAD//////8AAf/+AAB//gAAf/4AAH/+AAB//gAAf+8AAP/nAAH/5gAAfgIAAH4AAAB/5gAAf+4AAH/vAAD//wAB//4AAH/+AAB//gAAf/4AAH/+AAB//wAA/gAAP/wAAD/8AAAP/AAAD/wAAA/8AAAP/AAAD/wAAA/+AAAP/wAAH/w==";
		"printer" =	"iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACy0lEQVR4XsWXT2jTUBzHv6+2ppOmhW7qZuufSaegF+lEB8oKyhAETxV3cRcXB56UHQRPc3hUxJsyIojCYG4oMhBEHCg6GMgu4sUO/2CrXTe3dRbWJnkvJgG3dmm3JhndB3IKfN/nfd87/B5RVRWbiRtr0Pk2eReAAGuIQ7Fw74YIqBRC+ECYhwWSX5LChbEknp7SJJwKMApQBZZo2h/mU4mkcP51EiMd60sYd0AcGkI5XgZOLjZGQjxskJ5K/QUgns2+ryghdHau3QBVAFmCLer3hPjM15QAoNf2EVAZkCTYhspV3oGL8TjK8ex5BlIBtmEKqU7g8cjITQACAD+KIOyEr+BAgMjUx1zqIkqZByACuGUIPBgcvBpqbLwea2vzejyeEuXR4T+OGnDBQ7ricR5FSJLkezcxcSOVTucB3HYzxoRj0Si3xe0mTFVNl1BxIOBWgNWZbm2Tba2t3uHR0W5DgFK6d1tdnUtf3HyGgCw7aMAsYOD1egmldBc0dAGT5UoDBPx22GZphlTOphQrAoyhHB0RD159moZdzhz0mLJNAgqloBUsLx3njM8BFbOV4gYoY6gh5gZYjQXMDdR8KDFfwk0WKNPA/YEBbBRXenqqFTAzt+8ocjsjsIpvegrB7x+hoedXFmCMJeYXFo4EAgEXVlHwNUAKH0JTcwhWmeM4FGZ/gMvNmASy2SzTSPwXEN+Mjd2Jtbd7g8FgiUQ2GAHnD0BRYJmtvB/Z+gh2aALFk3cmk2Efxsfz+rrLI9m1/n4BQDeAwyjiZ7TL19DSTDRgFT13NvFN3T35JIdSPgN4CEC819e3PBGJxleE/vPci9SiJBEetiCQGJfTcvwoRd9wlSOZRFDIwzZUIrbHcsNSabmM/BJso8hGzroCRt3lOP3oN/LOGjCyHU3FhXwNpuK13gWBBthm7pdDAaYQcXYyLcA2RKzqabaZ/AOnTnNz1V9yZQAAAABJRU5ErkJggg==";
		"registry" = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAdVBMVEX///8AV4JS0/8AiMwAZpkplcEAhcdCvOg+tOAzpdEAXYtDxfUAYJAAaZ4VdqEkqeIFjc8AdrAAAAA4vO8PltYVkssajsIfpN8an9wzt+wAf74kjbkFX4opm8oPdKMpotQIdKgKgLgWgLAObJdIyvkfm9E2rt4Ym9+YAAABFklEQVQ4jbWT646DIBBGZbjUgijU2ou2u2u36/s/YgfRFIsl6Y+dRInOMXM+glkWFdSU0vh1AECVJABrnyKwry7MtimgJFiJGZwkAJwN7/t0qrFPX0XpojJQJiTm963+cxGFRVcVhN2PXaMlITncG4YjMExHCjaLq6rVcuvkchhTuO26PF3xCb8KgR3AQNYAOUzAbtyubAF0UrdCnM5dYcVLxsP3hkl9610yKvpmXG0AqOHww8iWo6wtSJlD3WCicPu9A8cVB5eT6OdAd/XAVww4SYbqp/NdaktNpbhkOpTMrz4BZvD3vohGQH30TWosI5vYAS9eH42wzDXXAeYl14HbEuDRqYMnwN+dyRn4TR15SP0Q/1QP08cMQlpnS9UAAAAASUVORK5CYII=";
		"service" = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAMAAABEpIrGAAAAllBMVEX////f8Pvk8/vZ7vrU7Pnp9fzv+P3z+v3P6vly2Pn4/P4nuOds1vgeteaJ3/xQyvJkzvPR1ddJx/Bh0vY1vup1pbhBw+25w8f29vYTseSA2vm54fZuqr14y+99z++gtL1gxOuEqbjDycvv8PDE5viTsb6R1PFpo7zO09WGrLlWpsJwqLyY3PZ30vOLscCs5Pnf4eF+tstsMFhhAAABcElEQVQ4ja2TWXeCMBCFg7hBQIIJi3FBbVMXAtr//+d6A4ikx+NDT+9DMjPfJWRCIOR/lRdKqY83hngBHd8YzgspF9lLVCgz3qXnyeMzH3Apa7yh8CB1J0RJqWwOUNcVxsDzqlohsBxKekEQGNxPnlny2V7tBZwHnEmtJSji4Ntut+acM+34hPiuRsx/cWNgN1CIkBvjvLZ5jJL2Z518rMHuAxrHFxYxZzbtNHOR1ijnbY+MRZCcTnpNpakwVrQ9smgJ6cmo10SbClbpDMsU0iOn12hhKsuoNRRRY6gct5dTNYZ9e5h5lmVlmkZzd9zJ/cQjCcrPszinQuzceSd3J1IR2wexEULoccvHX0hKm5OEUip2a8PXWxNvbH6gNDTl/Xa7x2ySMh9+bkFDYwBpZ4ziMjBcYKDXa8PBriek9i6whVNOsiRcrcISl7JscmsTJ9PzncLQ3OqktPnjOGi4oq+v/cMAvTPkhyQ5vPv1/qIfcy8kQrAPiNgAAAAASUVORK5CYII=";
		"share" = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADqElEQVR4XuWXTWgcZRjHf+/sOzPZbDZpNj3Ui6SWQlVML7lIY6naVCoEPy4iUmsolVIQPxG/yKEoePELYS2WEmtRT61KodHWj1ITxGM2CU0sTYvHoqbJbjYzO7vzmkd2DhnaZVIXg/hbXuY97D7/3zwzzzCrjDGsJRbw/xZQ3Bjn+Gdf+ABKKW6G6PLueeJxF6isRsAZPnbc7+npYXx8AsuyltfqJMLQLK+QrVvvolAoMLh3z3Ul9PXCjxwd9nt7eylMTNLV1UUY1og60djbrDhzy0oxPfMrUktq7t83GJdAxcMPHznq79i+nQvT0wh92+5mYWGB+fkinudRXlqiEa3pNC0tLXR0ZGlvb2d07GeE27ds4dz58xzYvy+SiAvg5A9/7O/a1c/Fi5fqbma5mEvnunVks1kcx8Z1XRrh+z6VSkCxWGTu2jU8z49qsXnzJs6cOcvBA09HEqgo/IMP8/7DDw0we/lK7EYCIx/ZyEqCUihZyJEV3Laxm6++PsWzzxz8W0IB+p333j85+NSTA0FQBW4QIvkkQzWcL4Vta4Y/+fTUi88/96gG0qmUHiiVypwe+RZQGBPS7CekdEQpCzA8uPsBJFOyNeDKuFSrVbl5MED//feKQKMzSY4BUxc4+/2PKJAsJBNwNWCJQFCtyg1GaAxhLeTcT6My/83IlzB23NOH4zhYShFEAmBpgKgDWmsMUCovkm3LYFmqKS0IQyM1sW073gEiAcJqTb4grafi+aTTrdI2mkFU09ZaakpWXMAQmlDmHDAEtRqZTHMFpKbr2oCSLMmMdcCE0gGE2dnZWHhzJHK5HIJkxS8Bxsh8uggbNtxC8xGJ6KhWCoid1pq2tlbZk6zzKl4+kYB0VrIkJxIwpVJx7MSJk9sk3BgaolT84aJEOiqY6PciUS4vjgFGAVngVmA9oEmO/dLLr45MFcYZ+eb0biAgOVXgd+A3DSzJBri6yqHvTKU0tuMAXAbmSI4BPMnWdZuiLFZJDYuasaiHX/3XX0pLlRQLvlqTt+LUTH5n/rU7fuHzx3xmPurPA6l/8lbsvPL6kJ9slhXlIMULm36ge+8jCFeOfcm7l+6j1a6hlCEJb791yAUqGgEyM1OTJCE0isXAIuz2qP0xiRDWPC5MTZCxQ6yEApIZvREJncBGOZIM/d3QnW/ksk4fwJ/FyujOQ1NvAlWSMRdNTiTg1I1sktEC5IAOBJgXD8AjGQGwCFS4STSQBdbLqu81/0XW/O/5X9ngrVtH8EzpAAAAAElFTkSuQmCC";
		"drive" = "R0lGODlhIAAgAHcAACH5BAEAABEALAAAAAAgACAAhwQEBDNmAF9fX2ZmZnd3dwCAAAD/AIaGhpaWlpmZmaCgpLKyssDAwMzMzNfX193d3ePj4///8P///wAAAAgMdATzJMjP73ARIAAAAAAABwIHqAAAAATzMMhiEM8CMAAAQATzbMjQlMjQX0ukkgAAAAAAAEB/LAAAAQAAAATzPAAADwT0AM6mHoeHlv///sjQX8hi+ggMdAAABwIHqAAAAEB/LLqrzQAAAAAAAEB/LATzqATzxM8CMMjQXwT0EMhtkQBrMABsMQgoSgAABAT2oAT2jACGRAgoSgBrMABsMQgoSgAABAT2wAT2rACGRAgoSgAABAT2wAAAAACGUAT2DM6mHoc6pv///shtUckNJwAAAEB/LAgMdAAABwIHqAAAAAAAAAAAAAAAB7/1EAAABwAAAEB/LAAAAEB/LAgMdAAABwIHqAAAAAAAAQAAAKEP8AT2PFvsolvsqgAAAL/1EAT1xFwabAAAAL/1EFvrPr/1EFufhgAAAOsC4ggMdAT0zMjP73ARIAAAAACwKQAAAAAAAAT02MhiEM8CMACwKQT1FMjQlMjQX0ui6gAAAAAAAAT1GABXWABZagEoSoUADwAAAAEoSgAAAAAAAQAAAAB5kwB5dQT1NAABAJ/zyEL8iAT1NAADAAQEBABmM19fX2ZmZnd3dwCAAAD/AIaGhpaWlpmZmaSgoLKyssDAwMzMzNfX193d3ePj4/////IlyQAAAHQMCCTzBO/PyCARcAAAAAcAAKgHAgAAADDzBBBiyDACz0AAAGzzBJTQyF/QyJKkSwAAAAAAACx/QAEAAAAAADzzBA8AAAD0BB6mzpaHh/7//1/QyPpiyHQMCAcAAKgHAgAAACx/QM2rugAAAAAAACx/QKjzBMTzBDACz1/QyBD0BJFtyFFtyO6jSwcAACx/QDz2BCQAAAEAAAAAAAAAAHAAAP///////wBzqADO2QgoSgAAAAABAAT2qAAAAgB5kwBzqADO2QgoSgAAAAABAAT2yAAAAgB5kwB5dQT2xAjOACMIHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8eJBEKKHEmyJMmCBBCoXMmypUuWAwAMPLCgps2bOHPeJCBAZoQDEoIKHUq06NAEPH0ChfDAgdMGUBlIxamgqgEDBRIoQNpTINCmDqBGncqgpgKzCgoUCIBga1KvEsCGHTv1ZtWqCfK67fozrsm/JdtyVRrXqOGiWgfDfQC4cUjBb/s+OEw5KGS+QO9q3syZM1KfPw+IHk26tGnSBEALBMC6tevXsF9/nE2bYEAAOw==";
		"hive" = "R0lGODlhIAAgAHcAACH5BAEAAMYALAAAAAAgACAAhwBTAABUAAFVAQBYAABZAABaAABbAANbAwBdAABeAABfAAZeBgBgAABhAAFhAQBjAABkAABlAABmAABnAARgBAdgBwBpAABqAABrAABsAABtAABvAARrBAdtBwhiCABwAABxAAByAABzAAB1AAB3AAB4AAB5AAB7AAB8AAB9AAB+AAB/ABd9FyZzJip2Kll1WWB2YGt+awCAAACCAACDAACEAACFAACGAACIAACJAACKAACLAACMAACOAACPAAuAAACQAACRAACSAACUAACVAACWAACXAACYAACaAACbAACcAACdAACeAAGeAQmbAAqbAAqcAAucAAqeABeRFwCgAAChAACpAACuAAqhAAqiAAujAAuoAAupAAusAAypAAyqAAysAAm1AAyyABOqABauABa5ARe6ARe8ARe+ARe/AR28Bz6DPi2jHS20GzC4HjKqMgDLAAPMAAbNABPQABbRACHTCSjWES7XGDDXGT3BKz7AKzraJV+XX1maWVm9WXWGdX2LfWaqZmqkamytbHamdkHcL0bdNEndN0zdOU3eOk7eO0/ePVHePVLfP1PJQ1nBTFnBWV3JVlPQQlPfQVTfQ1ffQ1jgRV7iTV7jTWLKX2naWWbkV3DmYHDmYXLmY3boZnnpbHvpbX/qcYLqc4Prd4Trd4nrfInsfozsgIzugpDug5LviJXqipXvip3ulJfwi5bwjJjwjp3xkqHxl6Lyl6bynKjxnqn0oKn0oar0oazyo631o7D1qbL2qbb3r7j3r7j3sLv4tL74tb74uL/4uMH6u///8AB4AAB5AAB7AAB8AAB9AAB+AAB/ABd9FyZzJip2Kll1WWB2YGt+awCAAACCAACDAACEAACFAACGAACIAACJAACKAACLAACMAACOAACPAACACwCQAACRAACSAACUAACVAACWAACXAACYAACaAACbAACcAACdAMPpzcQc3QgOUgAAAAABAAT0NAAAAsPYOcPpzcQc3QgOUgAAAAABAAT0VAAAAsPYOcPYKwT0UAj/AI0JHEiwoMGDCBMS1KPLkcKHB/PYYiXpDcSLxiK50qTGCpNABCNB8oORIKQfYaxUsdBnYB5XP4JMKSnQT5ASSixY4CNQjy1NYUqcYEHT2JQTOlsIzKSLVcecFooaY2FB6UBHklQmlWpsjcE3TLZyRRioD0+EVaowWaIEyZEiQ4QA6bFDx42oGKv0yjUrFpJSoTptCjLpUKE9FibkVcs2yVsiQYB0+eJli40ZF0SSTFhlGDBet5DASkUKFBANj0yVEkVjxhiYMtFSWdtWjJkyZXCcyMDGDR46M8j8DDrU4JVixYT5QiIi9eoTJjBEMWIFDpKmT3V6JZgGDZozPmSE/+j9G/qFIuitpGiTdWVVg8WIBfslYwWI6dVNlEgcAcKDBiXs0AQHHbhw0C6vjMLJCip8gF4RVpBgQW+LGFICAyM4MIgghCAEyiWWVKJCCh9okAEGF1hAhBZZYOEDCQqEQMFDjCiSCCIpaODGI6ucYsMEzolCwggJfODBQ28NEcQGYHzBxRZCSBABeXSMEAICCFTwEC610CJLD62oJsoIIkSAHxwhfIBABgs8pMonjNjBgyeN/GYlBA9aoaYBFxzwUCN1yAFHDncIimYIDTSgQAIJrFmABQM8NEcccMBxQ6WVhvAAG49gQskGBmBAwAQCPORDXTjUMIMMKaDwgBRQPEjhxAYZEHDBAAEA8hAqYs7A62ok/CrKiaMC8AdEdP4mQ7J0iMAsBpAKEMNFhVaqQrVoYpuYADBghCkcJ3z7wbcTBPDCWOgWFBAAOw==";
		"node" = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAEo0lEQVR4Xr2WX4hVVRvGf+9a6xzHMksKu5HMwoIiDSORqKnBTENBHSJSyrCboj+KFFlNn0M6dZExc2N/bvNC7cYMHSSCJOgiIgKjoKvGLJUgM2rMzzl7rbfjy96cs9tnDqIwDyz2XovDep73Wft9zhIgjIyMHFDVlaqJqYCIQ0RGt2zZsiYA0y+QNyf89fc4U4GZV82gWfRKYHoAelJKAJw8eQoRQUwlJaiCcnlQBVBm3jqfnLMnAAKQkhq5d0I9OHu6XEVSJSalEe3JpUNRxLhySKAN3jt6ao73PhvjyA+/4YRcAPTdfj3PLruJiSyhuUOqnUlAWoQlvYKWFygJcM5RC4FPvz3OntfWcPTY7wAsvPE61r91gM0P30LUhPMeEdsMGwCKzYt9QElJzerqx10VYD/0zpkL3sHY6XMcOnoq/2iutLUQhBqewcFtOHH03t+bEwBgRMseWsH/Xh+gr+8BsizSt3QpKQqGFldnByQ/dwFOjkdmzboa8neBvOrEG9uHqg7kzxgj23cMFUQ2RKS7AwUcDsGhwPE/G/T09BjRL813BQQHmohZRBAUrR4/kArLFQS5eAE4yFAeXDiHw4e/IHhn59mIiWXNtaiKSsGlVCDVuVQWuzrgiRFeWn0Hr/bfSb1e44P3d/H0M89x7nyDRhYJzpcLVmtTLhFVBxJwPiYaCpnz/NNQzkW16ms1Z65Im4AsJmvNmPTyBXgRFAOiklcHDsEHzzsHv2+26K8WUoCRLl80hxdX3cb5RuRiNMhkAlQEvEdyO8U5xHsAIw/iOPTVT+wdWFvKh3Vv7ueVtQtoJCkIUKiklBZzEeOqCBBNJQeciM1FhHqtTt0rNe849t98ELH1EMC5ckABxXupJUUrOaBQbhckJ3fOMTIyzDSf8P4GToyncj4IiDiCF17YtMmCrLf3fiMrojilSH//IybEOFo+EXK3CrJSnDaHqd768la8U/Zu3tPMhwnLB/KssErNOWXXrnc7OACqVr3tVxSmWu2CTg6Y+ixmpCyy/K65jI4eKX2EK+6eRxbNYmJMhQDKoKjeRrULmNSB3B1HI8vYtm4x259YAoVQVbIsWQcIAlIppFJcS0RVQEcHwJS3zaVNAK11EYSu6C4AAfECCYM4saGKPafVAzs++obRr8dKR7By8TwGHl1EmlC6B2JrX6TTEQBePElS3oYOJx6A4D3g+PjLH9k30M93P58GYMHca3lsaD+D6xcTMtDyXQRFKzngxCEw+d+xIK13326XUA+eY3/8vy0HrjA3EE+oKc6Hzn/TqsQYsRxw0uVGJK3zFUDyAHlzaAfTa4L3c9vvCZYJth9CCIENG540t+7r7UVTQjEY+VMbNxJVO3eBqrbd1ylgbTU4OEiBfc9/aL0/rciBMxPFBdOeu3fvrt6CoXAAbH9XrHVwwMqRtg0SWaa27pxn1ZKb+eTg55Z6gPX/6nvm5ySWA10upPk+XY6gcKCClEBE2fb4vTbKKPJeKEMmyQFXIZi9c+fbOtW4wAnMdoDZO9UoOAOA9358eHh4RoyRqYD33jgBBLgGmAfMsvnUQIEzwFgAzgJjwAmmFhPA2X8Bu4jRuurX3usAAAAASUVORK5CYII="
	}
	$icons.keys | % {
		$iconimageBytes = [Convert]::FromBase64String($icons[$_])
		$ims = New-Object IO.MemoryStream($iconimageBytes, 0, $iconimageBytes.Length)
		$ims.Write($iconimageBytes, 0, $iconimageBytes.Length);

		$global:imageList.Images.Add($_, [System.Drawing.Icon]::FromHandle((new-object System.Drawing.Bitmap -argument $ims).GetHIcon()) )
	}

	class FormHelper{
		static [object] getFormControl(
			$Control = "Form",
			[HashTable]$Member = @{}
		){
			If($Control -isnot "Windows.Forms.Control"){
				Try {
					$Control = New-Object Windows.Forms.$Control
				} Catch {
					$PSCmdlet.WriteError($_)
				}
			}
			$Styles = @{RowStyles = "RowStyle"; ColumnStyles = "ColumnStyle"}
			ForEach ($Key in $Member.Keys) {
				If ($Style = $Styles.$Key) {
					[Void]$Control.$Key.Clear()
					For ($i = 0; $i -lt $Member.$Key.Length; $i++) {
						[Void]$Control.$Key.Add((New-Object Windows.Forms.$Style($Member.$Key[$i])))
					}
				} Else {
					Switch (($Control | Get-Member $Key).MemberType) {
						"Property"	{$Control.$Key = $Member.$Key}
						"Method"  	{Invoke-Expression "[Void](`$Control.$Key($($Member.$Key)))"}
						"Event"   	{Invoke-Expression "`$Control.Add_$Key(`$Member.`$Key)"}
						Default   	{Write-Error("The $($Control.GetType().Name) control doesn't have a '$Key' member.")}
					}
				}
			}
			return $Control
		}


	}

	Class SetACL{
		$form = $null;
        $computerName = $null;

		[void] mnuFileOpen(){
			write-host 'test'
		}
        [string] getPermissions( $acl ){
            $accessMask = [ordered]@{
                [uint32]'0x80000000' = 'GenericRead'
                [uint32]'0x40000000' = 'GenericWrite'
                [uint32]'0x20000000' = 'GenericExecute'
                [uint32]'0x10000000' = 'GenericAll'
                [uint32]'0x02000000' = 'MaximumAllowed'
                [uint32]'0x01000000' = 'AccessSystemSecurity'
                [uint32]'0x00100000' = 'Synchronize'
                [uint32]'0x00080000' = 'WriteOwner'
                [uint32]'0x00040000' = 'WriteDAC'
                [uint32]'0x00020000' = 'ReadControl'
                [uint32]'0x00010000' = 'Delete'
                [uint32]'0x00000100' = 'WriteAttributes'
                [uint32]'0x00000080' = 'ReadAttributes'
                [uint32]'0x00000040' = 'DeleteChild'
                [uint32]'0x00000020' = 'Execute/Traverse'
                [uint32]'0x00000010' = 'WriteExtendedAttributes'
                [uint32]'0x00000008' = 'ReadExtendedAttributes'
                [uint32]'0x00000004' = 'AppendData/AddSubdirectory'
                [uint32]'0x00000002' = 'WriteData/AddFile'
                [uint32]'0x00000001' = 'ReadData/ListDirectory'
            }
            
            $simplePermissions = [ordered]@{
                [uint32]'0x1f01ff' = 'FullControl'
                [uint32]'0x0301bf' = 'Modify'
                [uint32]'0x0200a9' = 'ReadAndExecute'
                [uint32]'0x02019f' = 'ReadAndWrite'
                [uint32]'0x020089' = 'Read'
                [uint32]'0x000116' = 'Write'
            }
            
            $fileSystemRights = $acl | Select-Object -Expand FileSystemRights -First 1
            $fsr = $fileSystemRights.value__
            $permissions = @()
            $permissions += $simplePermissions.Keys | ForEach-Object {
                  if (($fsr -band $_) -eq $_) {
                    $simplePermissions[$_]
                    $fsr = $fsr -band (-bnot $_)
                  }
                }
            $permissions += $accessMask.Keys |
                Where-Object { $fsr -band $_ } |
                ForEach-Object { $accessMask[$_] }
                
            return $permissions    
        }
        [string] getAppliesTo( $acl ){
            $appliesTo = '';
            switch( $acl.PropagationFlags ){
                ([System.Security.AccessControl.PropagationFlags]::None){
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'This Folder, Subfolders and Files';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit)){
                        $appliesTo = 'This Folder and Subfolders';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'This Folder and Files';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::None)){
                        $appliesTo = 'This Folder only';
                    }
                    break;
                }
                ([System.Security.AccessControl.PropagationFlags]::InheritOnly){
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'Subfolders and Files only';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit)){
                        $appliesTo = 'Subfolders only';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'Files only';
                    }
                    break;
                }
                ([System.Security.AccessControl.PropagationFlags]::NoPropagateInherit){
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'This Folder, Subfolders and Files';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ContainerInherit)){
                        $appliesTo = 'This folder and Subfolders';
                    }
                    if($acl.InheritanceFlags -eq ( [System.Security.AccessControl.InheritanceFlags]::ObjectInherit)){
                        $appliesTo = 'This folder and Files';
                    }
                    break;
                }
            }
            return $appliesTo;
        }
        [void] logEvent($module, $msg){
            $this.form.Content.FindName('logfile').Text += "`r`n[$( get-date -Format 'MM/dd/yyyy hh:mm:ss' )] - $($module) - $($msg)";
            $this.form.Content.FindName('logfile').ScrollToEnd();

        }
        [void] expandFileSystem( $node ){
			$node.Items.clear()

            $path = "$($node.tag.split('|')[1])";
            write-host $path
            $this.logEvent("FileSystem", "Analyzing $($path)")
        
            $this.form.Content.FindName('selectedObject').Content = $path
            $this.form.Content.FindName('selectedObjectType').Content = "File / Directory"
            
            $this.form.Content.FindName('selectedObjectOwnerTable').Content = ( get-acl -path $path -errorAction SilentlyContinue | select -expand Owner )
            
            if( (Get-Item $path) -is [System.IO.DirectoryInfo]){
                gci -path "$($path)\"  -errorAction SilentlyContinue | ? {$_.PSIsContainer -eq $true } | sort Name | % {
                    try{
                        if( (gci ($_.fullname) -errorAction SilentlyContinue  ) -ne $null){
                            
                            $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                            $treeViewItem.Header = "$($_.name)";
                            $treeViewItem.Tag = "FileSystem|$($_.fullname)";
                            $treeViewItem.Add_Expanded({
                                $script:self.expandFileSystem($_.OriginalSource)
                            })
                            
                            if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | Measure-Object | select -expand count) -gt 0){
                                $treeViewItem.Items.Add($null)
                            }
                            $node.Items.Add($treeViewItem)
                            $dt = new-object System.data.DataTable;                        
                            get-acl -path $path -errorAction SilentlyContinue| select -expand access | % {
                                $dt += new-object PSObject -property @{
                                    Type = $_.AccessControlType;
                                    Name = $_.IdentityReference;
                                    Permissions = $this.getPermissions($_);
                                    "Applies To" = $this.getAppliesTo($_);
                                }
                            }
                            $this.form.Content.FindName('selectedObjectPermTable').ItemsSource = ( $dt | select Type, Name, Permissions, 'Applies To' )
                        }
                    }catch{

                    }
                }
            
                gci -path "$($path)\"  -errorAction SilentlyContinue | ? {$_.PSIsContainer -eq $false } | sort Name | % {
                    try{

                        $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                        $treeViewItem.Header = "$($_.name)";
                        $treeViewItem.Tag = "FileSystem|$($_.fullname)";
                        $treeViewItem.Add_Expanded({
                            $script:self.expandFileSystem($_.OriginalSource)
                        })
                        
                        
                        $node.Items.Add($treeViewItem)
                        $dt = new-object System.data.DataTable;                        
                        get-acl -path $path -errorAction SilentlyContinue| select -expand access | % {
                            $dt += new-object PSObject -property @{
                                Type = $_.AccessControlType;
                                Name = $_.IdentityReference;
                                Permissions = $this.getPermissions($_);
                                "Applies To" = $this.getAppliesTo($_);
                            }
                        }
                        $this.form.Content.FindName('selectedObjectPermTable').ItemsSource = ( $dt | select Type, Name, Permissions, 'Applies To' )
                        
                    }catch{

                    }
                }
            }else{
                $dt = new-object System.data.DataTable;                        
                get-acl -path $path -errorAction SilentlyContinue| select -expand access | % {
                    $dt += new-object PSObject -property @{
                        Type = $_.AccessControlType;
                        Name = $_.IdentityReference;
                        Permissions = $this.getPermissions($_);
                        "Applies To" = $this.getAppliesTo($_);
                    }
                }
                $this.form.Content.FindName('selectedObjectPermTable').ItemsSource = ( $dt | select Type, Name, Permissions, 'Applies To' )
            }
            
        }

		[void] expandRegistry( $node ){
		clear
			# $node | fl | out-string | write-host
            $path = "$($node.tag.split('|')[1])\";

			$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel2.controls['contentPanel'].controls['selObject'].text = $path
			$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel2.controls['contentPanel'].controls['selObjectType'].text = "Registry"

			# write-host $path;
            # gci -path $path  -errorAction SilentlyContinue | ft |out-string | write-host
			$node.nodes.clear()
			gci -path $path  -errorAction SilentlyContinue | ? {$_.PSIsContainer -eq $true } | sort Name | % {
				$node.Nodes.Add($_.PSChildname,$_.PSChildname, $global:imageList.Images.indexOfKey('node'), $global:imageList.Images.indexOfKey('node'))
				$node.Nodes[$_.PSChildname].tag = "Registry|$($_.name.replace('HKEY_LOCAL_MACHINE','hklm:').replace('HKEY_CURRENT_USER','hkcu:'))"

				if( (gci ($_.name.replace('HKEY_LOCAL_MACHINE','hklm:').replace('HKEY_CURRENT_USER','hkcu:')) -errorAction SilentlyContinue  | ? { $_.PSIsContainer -eq $true } | Measure-Object | select -expand count) -gt 0){
					$node.Nodes[$_.PSChildname].Nodes.Add($null,$null)
				}

			}
        }

        [void] nodeClicked( $tree ){
			if($tree.selectedNode.level -le 1){
				$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel2.controls['contentPanel'].controls['selObject'].text = $tree.selectedNode.text
			}elseif($tree.selectedNode.tag -ne $null){
                switch( $tree.selectedNode.tag.split('|')[0] ){
                    "FileSystem" {
                        $this.expandFileSystem( $tree.selectedNode );
                        break;
                    }
					"Registry" {
                        $this.expandRegistry( $tree.selectedNode );
                        break;
                    }
                }
            }

        }

		[void] generateForm(){
			
            get-psdrive | ? {$_.Provider.Name -eq 'FileSystem' } | Sort Name | % {
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes.add( "$($_.name):", "$($_.name):", $global:imageList.Images.indexOfKey('drive'), $global:imageList.Images.indexOfKey('drive') )
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes[ "$($_.name):" ].Tag = "FileSystem|$($_.name):"

				if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | ? { $_.PSIsContainer -eq $true } | Measure-Object | select -expand count) -gt 0){
					$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['FileSystem'].Nodes[ "$($_.name):" ].Nodes.Add($null,$null)
				}

            }

            $this.getPrinters() | % {
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Printers'].Nodes.add("$($_.name)", "$($_.name)", $global:imageList.Images.indexOfKey('printer'), $global:imageList.Images.indexOfKey('printer') )
            }

            get-psdrive | ? {$_.Provider.Name -eq 'Registry' } | Sort Name | % {
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Registry'].Nodes.add("$($_.name):", "$($_.name):", $global:imageList.Images.indexOfKey('hive'), $global:imageList.Images.indexOfKey('hive') )

				$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Registry'].Nodes[ "$($_.name):" ].Tag = "Registry|$($_.name):"
				if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | ? { $_.PSIsContainer -eq $true } | Measure-Object | select -expand count) -gt 0){
					$this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Registry'].Nodes[ "$($_.name):" ].Nodes.Add($null,$null)
				}
            }

            $this.getServices() | % {
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Services'].Nodes.add("$($_.name)", "$($_.name)", $global:imageList.Images.indexOfKey('service'), $global:imageList.Images.indexOfKey('service') )
            }

            get-SmbShare | Sort Name | % {
                $this.form.Controls['mainContent'].panel1.controls['mainBody'].panel1.controls['treeNodes'].Nodes['root'].Nodes['Shares'].Nodes.add("$($_.name)", "$($_.name)", $global:imageList.Images.indexOfKey('share'), $global:imageList.Images.indexOfKey('share') )
            }
		}
       
        [object] getPrinters(){
            return get-printer -computerName $this.computerName | Sort Name;
        }
        
        [object] getServices(){
            return get-service -computerName $this.computerName | Sort Name;
        }

		SetACL(){
            $script:self = $this
            $this.computerName = ( hostname )
			
            $reader = New-Object System.Xml.XmlNodeReader ([xml](gc "$( $PSScriptRoot)\SetACL-gui.xaml"))
            $xamlReader = iex "[Windows.Markup.XamlReader]"
            $this.form = $xamlReader::Load( $reader ) 
                
            $this.form.Content.FindName('selectedObject').Content = $this.computerName 
            $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Header = $this.computerName 
 
            
            get-psdrive | ? {$_.Provider.Name -eq 'FileSystem' } | Sort Name | % {
                $treeViewItem = iex "[Windows.Controls.TreeViewItem]::new()"
                $treeViewItem.Header = "$($_.name):";
                $treeViewItem.Tag = "FileSystem|$($_.name):";
                $treeViewItem.Add_Expanded({
                    $script:self.expandFileSystem($_.OriginalSource)
                })
                $treeViewItem.Add_Selected({
                    $script:self.expandFileSystem($_.OriginalSource)
                })
                $subItemIndex = $this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(0).Items.Add( $treeViewItem )
				if( (gci "$($_.fullname)\" -errorAction SilentlyContinue  | ? { $_.PSIsContainer -eq $true } | Measure-Object | select -expand count) -gt 0){
					$this.form.Content.FindName('treeObjects').Items.GetItemAt(0).Items.GetItemAt(0).Items.GetItemAt($subItemIndex).Items.Add($null)
				}

            }
            
            $this.form.ShowDialog() | out-null
		}
	}
}
Process{
	$setAcl = [SetACL]::new();
}
End{
	$error | select *
}
