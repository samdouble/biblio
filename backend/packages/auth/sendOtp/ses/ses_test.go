package ses

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
)

func TestSendOtpEmail_loadConfigError(t *testing.T) {
	orig := loadAWSConfig
	loadAWSConfig = func(ctx context.Context, region string) (aws.Config, error) {
		return aws.Config{}, errors.New("config boom")
	}
	t.Cleanup(func() { loadAWSConfig = orig })

	err := SendOtpEmail(context.Background(), "a@b.co", "123456", "us-east-1")
	if err == nil {
		t.Fatal("expected error")
	}
	if want := "load aws config"; !strings.Contains(err.Error(), want) {
		t.Fatalf("error should mention %q, got: %v", want, err)
	}
}

func TestSendOtpEmail_sendFailsUnreachableEndpoint(t *testing.T) {
	t.Setenv("AWS_EC2_METADATA_DISABLED", "true")
	orig := loadAWSConfig
	loadAWSConfig = func(ctx context.Context, region string) (aws.Config, error) {
		return config.LoadDefaultConfig(ctx,
			config.WithRegion(region),
			config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("x", "y", "")),
			config.WithEndpointResolverWithOptions(aws.EndpointResolverWithOptionsFunc(
				func(service, region string, options ...interface{}) (aws.Endpoint, error) {
					return aws.Endpoint{URL: "http://127.0.0.1:1", HostnameImmutable: true}, nil
				})),
		)
	}
	t.Cleanup(func() { loadAWSConfig = orig })

	err := SendOtpEmail(context.Background(), "a@b.co", "999888", "us-east-1")
	if err == nil {
		t.Fatal("expected SendEmail to fail against unreachable endpoint")
	}
}
