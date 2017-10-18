node default {

}

node /^dev-webapp.*$/ {
    #Sample node with hardcode secret

    $mysecretkey  = Sensitive('oL>3K+aX1kF')
    $mydbpassword  = Sensitive('super magic dragon')

    notify { "****** Secret key is: ${mysecretkey.unwrap} *******": }
    notify { "****** DB Password is: ${mydbpassword.unwrap} *******": }
    notify { "******* Writing secret key to file /etc/mysecretkey ******": }
    file { '/etc/mysecretkey':
      ensure => file,
      content => $mysecretkey,
    }
}


node /^prod-webapp.*$/ {

    #Sample node with secret store in conjur

    class { conjur:
      appliance_url      => 'https://conjur/api',
      authn_login        => "host/${::trusted['hostname']}",
      host_factory_token => Sensitive('1ven1vk3ggkkyy3mbz56j19jrcek3g8906a1fn5njd1wxeea034zqbxe'),
      ssl_certificate    => file('/etc/conjur-ca.pem'),
      version            => 4,
    }

    $mysecretkey = conjur::secret('puppetdemo/secretkey')
    $mydbpassword = conjur::secret('puppetdemo/dbpassword')


    notify { "****** Secret key is: ${mysecretkey.unwrap} *******": }
    notify { "****** DB Password is: ${mydbpassword.unwrap} *******": }
    notify { "******* Writing secret key to file /etc/mysecretkey ******": }
    file { '/etc/mysecretkey':
      ensure => file,
      content => $mysecretkey,
      mode => '0600'
    }
}

