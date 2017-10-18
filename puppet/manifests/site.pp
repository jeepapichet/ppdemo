node default {

}

node /^dev-webapp.*$/ {
    #Sample node with hardcode secret

    $mysecretkey  = Sensitive('H@rdC0de$e(e1')
    $mydbpassword  = Sensitive('puff, the magic dragon')

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
      host_factory_token => Sensitive('PLACE_HF_TOKEN_HERE'),
      ssl_certificate    => file('/etc/conjur.pem'),
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

