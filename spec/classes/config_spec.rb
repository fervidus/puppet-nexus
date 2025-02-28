require 'spec_helper'

describe 'nexus' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        describe 'nexus::config', type: :class do
          let(:params) do
            {
              'nexus_root' => '/foo',
              'nexus_home_dir'    => '/bar',
              'nexus_host'        => '1.1.1.1',
              'nexus_port'        => '8888',
              'nexus_context'     => '/baz',
              'nexus_work_dir'    => '/foom',
              'version'           => '2.11.2',
              'nexus_data_folder' => '',
            }
          end

          context 'with nexus version 2.x test values' do
            it { is_expected.to contain_class('nexus::config') }

            it {
              is_expected.to contain_file_line('nexus-application-host').with(
                'path'  => '/foo//bar/conf/nexus.properties',
                'match' => '^application-host=',
                'line'  => 'application-host=1.1.1.1',
              )
            }

            it {
              is_expected.to contain_file_line('nexus-application-port').with(
                'path'  => '/foo//bar/conf/nexus.properties',
                'match' => '^application-port=',
                'line'  => 'application-port=8888',
              )
            }

            it {
              is_expected.to contain_file_line('nexus-webapp-context-path').with(
                'path'  => '/foo//bar/conf/nexus.properties',
                'match' => '^nexus-webapp-context-path=',
                'line'  => 'nexus-webapp-context-path=/baz',
              )
            }

            it {
              is_expected.to contain_file_line('nexus-work').with(
                'path'  => '/foo//bar/conf/nexus.properties',
                'match' => '^nexus-work=',
                'line'  => 'nexus-work=/foom',
              )
            }
          end
        end
      end
    end
  end
end

# vim: sw=2 ts=2 sts=2 et :
